# Proyecto #2 - Bases de Datos II

<p align="center">
  <img src="https://img.shields.io/badge/Curso-IC4302_Bases_de_Datos_II-orange" />
  <img src="https://img.shields.io/badge/-II_Semestre_2026-brown" />
</p>

---
## Información General

**Nombre y carné de los integrantes**: 
- Juan David Mora Acuña | 2024126028
- Deywenie Smith Gregory | 2024096722

**Estado del proyecto:** 
Muy bueno/Completado

**Objetivos alcanzados:**
- Infraestructura de 3 nodos: Corporativo (Ubuntu), sucursal San José (Windows) y sucursal Limón (Red Hat), cada uno con su propio servidor de SQL Server.
- Fragmentación horizontal: la facturación, los pedidos, las transacciones y el inventario quedan en la sucursal a la que pertenece cada cliente. Las compras a proveedores quedan centralizadas en el Corporativo.
- Fragmentación vertical: los datos sensibles de clientes, proveedores y personas solo existen en el Corporativo.
- Replicación transaccional: el catálogo (productos y sus tablas relacionadas, clientes, proveedores, ciudades, usuarios, etc.) se replica desde el Corporativo hacia las dos sucursales.
- Servidores vinculados (linked servers) entre el Corporativo y las sucursales, con usuarios de solo lectura.
- Vista materializada (o similar) en el Corporativo: tablas de resumen de ventas que se refrescan con un job del SQL Server Agent.
- Estadísticas filtradas por sucursal o consolidadas.
- Tabla de usuarios con la contraseña cifrada usando el cifrado nativo de SQL Server.
- Roles Administrador y Corporativo, relacionados con usuarios de la base de datos que solo pueden ejecutar procedimientos almacenados.
- Manejo de concurrencia al modificar productos desde diferentes sucursales y al facturar productos de un mismo inventario.
- Plan ante fallos cuando un nodo no responde.
- Se mantienen las funcionalidades del Proyecto #1, adaptadas a los roles del Proyecto #2.

**Objetivos no alcanzados:**  
No se presentaron objetivos no alcanzados. Se desarrollaron todos los requerimientos solicitados en el proyecto.

--- 

## Descripción del trabajo
El proyecto consiste en llevar la base de datos `WideWorldImporters` del Proyecto #1 a un esquema distribuido. La empresa tiene dos sucursales (San José y Limón) y una oficina corporativa en Plaza Roble, Escazú, que supervisa ambos negocios. Cada sucursal tiene su propia base de datos para no depender de la red en el trabajo del día a día, y el Corporativo es el dueño del catálogo y de los datos sensibles.

Igual que en el Proyecto #1, toda la lógica de consulta, filtrado, agrupación y transformación de los datos está en procedimientos almacenados. La API solo recibe las solicitudes, las manda al nodo que corresponde según el usuario que inició sesión y devuelve los resultados. La página web solo muestra la información.

## Herramientas utilizadas
- **SQL Server 2022 Developer** como motor de base de datos en los 3 nodos.
- **Windows** para la sucursal San José (instalación nativa de SQL Server).
- **Docker Desktop** y **Docker Compose** para levantar los contenedores del Corporativo (imagen de SQL Server sobre **Ubuntu**) y de Limón (imagen de SQL Server sobre **Red Hat**).
- **SQL Server Management Studio (SSMS)** para ejecutar los scripts, configurar la replicación y revisar los agentes.
- **SQL Server Agent** para los agentes de replicación y el job de la vista materializada.
- **Visual Studio Code** para el desarrollo de la API y la página web.
- **Node.js** y **Express** para la API, con los paquetes `mssql`, `jsonwebtoken`, `dotenv` y `cors`.
- **React + Vite** para la página web, con **Material UI**, **React Router** y **Leaflet** para los mapas.
- **Tailscale** para conectar las computadoras de los integrantes como si estuvieran en la misma red, y así poder trabajar y presentar el sistema de forma remota.
- **Git** y **GitHub** para el control de versiones.
- **Microsoft Learn** como guía para la replicación, los servidores vinculados y el cifrado.

## Arquitectura del sistema

| Nodo | Ubicación | Sistema operativo | Dónde corre | Puerto | Base de datos |
|---|---|---|---|---|---|
| Corporativo | Plaza Roble, Escazú | Ubuntu | Contenedor `sqlcorporativo` | 1440 | `WWI_Corporativo` |
| Sucursal San José | San José | Windows | SQL Server nativo | 1433 | `WWI_SanJose` |
| Sucursal Limón | Limón | Red Hat | Contenedor `sqllimon` | 1441 | `WWI_Limon` |

Los dos contenedores están en una misma red de Docker (`red_wwi`), y el Corporativo llega al SQL Server de Windows por medio de `host-gateway`. La API y la página web corren en la misma computadora que los servidores.

## Diseño distribuido

### Fragmentación horizontal
El criterio es la ubicación del cliente. Según el territorio de ventas de su ciudad de entrega, cada cliente se asigna a una sola sucursal. Esta regla se guarda en la tabla `dbo.AsignacionSucursal` y en la columna `Sucursal` de `Sales.Customers`.

| Sucursal | Territorios |
|---|---|
| San José | Far West, Rocky Mountain, Southwest, Plains |
| Limón | New England, Mideast, Southeast, Great Lakes, External |

El catálogo de clientes es el mismo en las dos sucursales, tal como lo pide el enunciado. Lo que se fragmenta es lo que genera cada cliente (fragmentación derivada): facturas, líneas de factura, pedidos, transacciones de clientes y movimientos de inventario. Así una factura y todo lo relacionado con ella quedan en el mismo nodo que su cliente, y cada sucursal puede facturar sin consultar a otro servidor.

Las compras a proveedores quedan solo en el Corporativo, porque los proveedores le venden a la empresa y no a una sucursal en específico. El inventario se repartió entre las dos sucursales y cada una maneja el suyo.

Resultado de la fragmentación:

| | San José | Limón | Total |
|---|---|---|---|
| Clientes | 299 | 364 | 663 |
| Facturas | 32,182 | 38,328 | 70,510 |

El total de facturas es igual al de la base original, por lo que no se perdió ni se repitió ninguna factura. Para que los registros nuevos no choquen entre sucursales, las secuencias se reiniciaron en rangos distintos: San José desde 1,000,000 y Limón desde 2,000,000.

### Fragmentación vertical
Los datos sensibles de privacidad y forma de contacto solo están en el Corporativo:
- **Clientes:** 12 columnas (teléfonos, fax, sitio web, direcciones, ubicación y contactos).
- **Proveedores:** 17 columnas (lo mismo que clientes, más los datos bancarios).
- **Personas:** 7 columnas (usuario, contraseña, teléfonos y correo).

Las sucursales reciben el resto de las columnas por medio de la replicación con filtro de columnas. Cuando un administrador abre el detalle de un cliente o proveedor, el procedimiento une la parte local con la parte sensible, que se lee del Corporativo por servidor vinculado a través de las vistas `ClientesSensibles` y `ProveedoresSensibles`. El usuario del servidor vinculado solo puede leer esas vistas y no las tablas.

### Asignación
| Datos | Nodo | Motivo |
|---|---|---|
| Facturación, pedidos y transacciones de sus clientes | Cada sucursal | Es lo que más se usa en la sucursal |
| Inventario | Cada sucursal | Cada sucursal vende de su propia bodega |
| Catálogo (productos, clientes, proveedores, ciudades, etc.) | Corporativo, replicado a las sucursales | Todas las sucursales necesitan el mismo catálogo |
| Datos sensibles | Solo Corporativo | Lo pide el enunciado y reduce la exposición de los datos |
| Compras a proveedores | Solo Corporativo | Las compras están centralizadas |
| Usuarios del sistema | Corporativo, replicado a las sucursales | Cada sede puede validar el inicio de sesión aunque otra esté caída |
| Resumen de ventas (vista materializada) | Solo Corporativo | Las estadísticas no consultan las sucursales en cada reporte |

### Replicación
Se usó la **replicación transaccional** de SQL Server. El Corporativo es el publicador y el distribuidor, y las dos sucursales son suscriptoras con suscripciones push. La publicación se llama `CatalogosWWI` y tiene 20 artículos, entre ellos `StockItems`, `StockItemStockGroups`, `StockGroups`, `Colors`, `PackageTypes`, `Customers`, `Suppliers`, `People`, `Cities` y `Usuarios`.

Como las sucursales ya tenían los datos, las suscripciones se crearon con `replication support only`, sin snapshot inicial. Cada vez que se crea, modifica o elimina un producto en el Corporativo, el cambio llega a San José y a Limón en pocos segundos. Si una sucursal está apagada, los cambios quedan guardados en la base de distribución y se entregan cuando vuelve.

Cuando llega un producto nuevo, un trigger en cada sucursal le crea su fila de inventario en 0 con ubicación "Sin asignar", y el administrador de esa sucursal le pone su cantidad.

### Vista materializada
SQL Server no permite vistas indexadas sobre tablas de otros servidores, así que se hizo algo similar. El Corporativo tiene tablas de resumen (`ResumenFacturas`, `ResumenDetalleFacturas` y `ResumenMovimientosInventario`) que se llenan con los datos de las dos sucursales por medio de los servidores vinculados. Un job del SQL Server Agent las refresca cada 30 minutos, y desde la página de estadísticas también se puede actualizar en el momento con el botón **Actualizar ahora**.

Al principio el job corría cada 5 minutos, pero eso cargaba mucho los servidores, así que se cambió a 30 minutos.

Los reportes de ventas reciben el parámetro `@Sucursal`: si se manda `SanJose` o `Limon` muestran solo esa sucursal, y si va vacío muestran el consolidado. Los reportes de compras siempre son consolidados porque las compras están centralizadas.

## Seguridad

### Usuarios y cifrado
La tabla `dbo.Usuarios` guarda `iduser`, `username`, `password`, `fullname`, `active`, `rol`, `email`, `hiredate` y `sucursal`. La contraseña se cifra con la jerarquía nativa de SQL Server: **master key → certificado (`CertificadoUsuarios`) → llave simétrica AES-256 (`LlaveUsuarios`)**. La llave se creó igual en los 3 nodos, por eso una contraseña cifrada en el Corporativo se puede validar en cualquier sucursal.

Los usuarios se crean con `CrearUsuario` en el Corporativo y se replican. No se hizo un módulo de gestión de usuarios en la página, porque el enunciado dice que no es necesario.

### Relación entre usuarios de la aplicación y de la base de datos
- Cada rol tiene su propio login en SQL Server: `api_sanjose`, `api_limon`, `api_corporativo` y `api_productos`.
- Estos logins **solo tienen permiso de `EXECUTE`** sobre los procedimientos que su rol necesita, no pueden leer tablas.
- Al iniciar sesión, la API valida al usuario con `ValidarUsuario` en la sede elegida y genera un token (JWT) con su rol y sucursal. Con ese token, cada petición se manda al nodo que corresponde.
- Si alguien intenta entrar a una opción de otro rol, lo bloquea la API, y si se salta la API, lo bloquea SQL Server por falta de permisos.

Además, las columnas bancarias de los proveedores usan el **Dynamic Data Masking** que ya trae WideWorldImporters, por eso desde las sucursales se ven como `xxxx`.

## Concurrencia
- **Productos (catálogo replicado):** se usa concurrencia optimista. Cada producto tiene una versión (la columna `ValidFrom`). Al editar, se manda la versión que tenía el producto cuando se abrió el formulario, y si otro administrador lo modificó antes, el cambio se rechaza y la página pide cargar los datos nuevos. Para crear productos se usa `UPDLOCK, HOLDLOCK` y así dos administradores no pueden crear el mismo nombre al mismo tiempo.
- **Facturas e inventario:** `CrearFactura` bloquea la fila del inventario con `UPDLOCK`, revisa que haya suficientes unidades en la sucursal y las rebaja en la misma transacción. Si dos facturas quieren vender el mismo producto al mismo tiempo, la segunda espera y luego ve la cantidad ya rebajada.
- **Vista materializada:** el refresco usa `sp_getapplock` para que no se ejecuten dos actualizaciones al mismo tiempo.

## Plan ante fallos

| Nodo que no responde | Qué pasa |
|---|---|
| Una sucursal | La otra sucursal funciona normal. Las estadísticas muestran los datos del último corte. Los productos se pueden crear y editar, y la replicación los entrega cuando la sucursal vuelve. No se permite eliminar productos, porque no se puede revisar si tienen ventas en esa sucursal. |
| Corporativo | Los administradores pueden iniciar sesión porque la tabla de usuarios está replicada. Se puede consultar y facturar normal. El detalle de clientes y proveedores muestra solo los datos de la sucursal con el aviso "No disponible". No se pueden modificar productos porque el catálogo maestro está en el Corporativo. |

Para que la página no se quede esperando, los servidores vinculados tienen un tiempo de espera de 5 segundos y los procedimientos revisan la conexión con `sp_testlinkedserver`. La API responde con un mensaje claro cuando una sede no responde, y en la pantalla de inicio de sesión se muestra cuáles sedes están en línea.

## Instrucciones de instalación

### Requisitos
- Windows 10 u 11 con SQL Server 2022 Developer (instancia predeterminada, autenticación mixta y TCP/IP habilitado en el puerto 1433).
- Docker Desktop con WSL 2.
- SQL Server Management Studio.
- Node.js.

### Instalación de los nodos
1. Clonar el repositorio:

    ```bash
    git clone https://github.com/deysmith/Proyecto2-Bases-de-Datos-ll.git
    cd Proyecto2-Bases-de-Datos-ll
    ```

2. En la carpeta [Infraestructura](Infraestructura), crear un archivo `.env` con la contraseña de `sa` y la intercalación:

    ```env
    SA_PASSWORD=contraseña
    COLACION=Latin1_General_100_CI_AS
    ```

3. Levantar los contenedores del Corporativo y de Limón:

    ```bash
    cd Infraestructura
    docker compose up -d
    ```

4. Restaurar la base `WideWorldImporters` en los 3 servidores con los nombres `WWI_Corporativo`, `WWI_SanJose` y `WWI_Limon`. El respaldo se descarga desde la página de Microsoft: [Instalación de BD de Wide World Importers](https://learn.microsoft.com/en-us/sql/samples/wide-world-importers-oltp-install-configure?view=sql-server-ver17). Para los contenedores, el archivo `.bak` se copia con `docker cp`.

### Ejecución de los scripts
Los scripts están en la carpeta [Script/Proyecto2](Script/Proyecto2) y se ejecutan desde SSMS. Los scripts de cada nodo (`corporativo.sql`, `sanjose.sql` y `limon.sql`) están separados por bloques comentados y se ejecutan por partes, en este orden:

1. **Preparación y fragmentación:** en cada nodo, los bloques que quitan la seguridad por filas y el versionado temporal, asignan la sucursal a los clientes y aplican la fragmentación horizontal y vertical.
2. **Cifrado y usuarios:** en cada nodo, la jerarquía de cifrado, la tabla de usuarios, `ValidarUsuario` y los logins de la API.
3. **Replicación:** en el Corporativo, los bloques del distribuidor, la publicación, los artículos, los filtros de columnas y las suscripciones. Después se crean los usuarios del sistema con `CrearUsuario`.
4. **Servidores vinculados:** primero los logins de solo lectura de cada nodo y luego los servidores vinculados en los 3 nodos.
5. **Sinónimos y generales:** en los 3 nodos, `sinonimos.sql` y luego `generales.sql`.
6. **Productos, inventario y vista materializada:** en el Corporativo, los procedimientos de productos, las tablas de resumen y el job. En las sucursales, el trigger de productos nuevos y `ActualizarInventarioProducto`.
7. **Procedimientos de los módulos:**
   - En San José y Limón: los archivos de la carpeta [Sucursales](Script/Proyecto2/Sucursales), dejando `permisos.sql` de último.
   - En el Corporativo: `estadisticas.sql`. Este archivo **siempre va después** de `generales.sql`, porque los dos crean el procedimiento `ObtenerFechasVentasAnioProveedor` y el del Corporativo tiene que quedar con la versión de `estadisticas.sql`.

Los archivos compartidos revisan al inicio en qué base se están ejecutando, y si es la base equivocada no ejecutan nada.

### Ejecución del programa
En la carpeta [Api](Api) se debe crear un archivo `.env` con las conexiones a los 3 nodos. Se puede copiar el archivo `.env.example` y completar las contraseñas:

```env
PORT=3000
TOKEN_SECRETO=texto_secreto

SJ_SERVER=localhost
SJ_PORT=1433
SJ_DB=WWI_SanJose
SJ_USER=api_sanjose
SJ_PASSWORD=contraseña

LIMON_SERVER=localhost
LIMON_PORT=1441
LIMON_DB=WWI_Limon
LIMON_USER=api_limon
LIMON_PASSWORD=contraseña

CORP_SERVER=localhost
CORP_PORT=1440
CORP_DB=WWI_Corporativo
CORP_USER=api_corporativo
CORP_PASSWORD=contraseña

PRODUCTOS_USER=api_productos
PRODUCTOS_PASSWORD=contraseña
```

Luego se abren dos terminales, una para la API y otra para la página web.

#### Terminal de la API
```bash
cd Api
npm install
npm run dev
```

#### Terminal de la Página Web
```bash
cd Website
npm install
npm run dev
```

La página queda disponible en `http://localhost:5173`. Vite pasa las peticiones de `/api` a la API, por lo que desde otra computadora de la red de Tailscale se puede entrar con la IP de la computadora donde corre el sistema.

### Usuarios de prueba
| Usuario | Contraseña | Rol | Sede |
|---|---|---|---|
| `corporativo` | `Corporativo*2026` | Corporativo | Corporativo |
| `admin_sanjose` | `SanJose*2026` | Administrador | San José |
| `admin_limon` | `Limon*2026` | Administrador | Limón |

Las contraseñas de este proyecto son de prueba y solo se usan en un ambiente local.

## Estructura del programa

### Scripts
```text
Script/
├── creacionSinonimos.sql        (Proyecto #1)
├── Stored Procedures/           (Proyecto #1)
└── Proyecto2/
    ├── corporativo.sql
    ├── sanjose.sql
    ├── limon.sql
    ├── sinonimos.sql
    ├── generales.sql
    ├── estadisticas.sql
    └── Sucursales/
        ├── clientes.sql
        ├── proveedores.sql
        ├── inventario.sql
        ├── ventas.sql
        └── permisos.sql
```

- ``corporativo.sql``: preparación y fragmentación del Corporativo, cifrado, tabla de usuarios, replicación, servidores vinculados, vistas de datos sensibles, procedimientos de productos y vista materializada.
- ``sanjose.sql`` y ``limon.sql``: preparación y fragmentación de cada sucursal, cifrado, logins, servidor vinculado al Corporativo, trigger de productos nuevos y manejo del inventario.
- ``sinonimos.sql``: sinónimos de las tablas, se ejecuta en los 3 nodos.
- ``generales.sql``: procedimientos para los combobox y campos de búsqueda, se ejecuta en los 3 nodos.
- ``estadisticas.sql``: los 10 reportes con el filtro por sucursal o consolidado, solo en el Corporativo.
- ``Sucursales/``: procedimientos de clientes, proveedores, inventario y ventas de las sucursales, y los permisos del rol Administrador.
- Los scripts del Proyecto #1 se dejaron como referencia.

### Infraestructura
```text
Infraestructura/
└── docker-compose.yml
```

Define los contenedores del Corporativo (Ubuntu) y de Limón (Red Hat), sus puertos, sus volúmenes y la red entre ellos.

### API
La API fue desarrollada con `Node.js` y `Express`. A diferencia del Proyecto #1, ahora tiene una conexión por cada nodo y decide a cuál mandar cada consulta según el usuario que inició sesión.

```text
Api/
└── src/
    ├── db.js
    ├── helpers.js
    ├── seguridad.js
    ├── server.js
    └── routes/
        ├── auth.js
        ├── clientes.js
        ├── facturas.js
        ├── generales.js
        ├── productos.js
        ├── proveedores.js
        └── reportes.js
```

- ``db.js``: conexiones a San José, Limón y el Corporativo (una para estadísticas y otra para productos).
- ``seguridad.js``: revisa el token y el rol de cada petición.
- ``routes/auth.js``: inicio de sesión y estado de las sedes.

### Aplicación web
La interfaz fue desarrollada con `React + Vite`. Se agregó la página de inicio de sesión, el menú según el rol y la sede del usuario, y el selector de sucursal o consolidado en las estadísticas. La sesión se guarda por pestaña, así se puede tener una pestaña de San José y otra de Limón en el mismo navegador.

## Funcionalidades del sistema

### Inicio de sesión
- Selección de la sede (San José, Limón o Corporativo).
- Indicador de las sedes que están en línea.
- Menú según el rol del usuario.

### Administrador (por sucursal)
**Clientes**
- Consulta del catálogo de clientes con filtros.
- Indicador de la sucursal a la que pertenece cada cliente.
- Detalle del cliente con sus datos sensibles traídos del Corporativo y su ubicación en el mapa.

**Proveedores**
- Consulta de proveedores con filtros.
- Detalle del proveedor con sus datos sensibles traídos del Corporativo.

**Inventario**
- Consulta de productos con la cantidad disponible en la sucursal.
- Creación, edición y eliminación de productos, que se replican a todas las sedes.*
- Actualización de la cantidad y la ubicación del inventario de la sucursal.

**Ventas**
- Consulta de las facturas de la sucursal con filtros.
- Detalle del encabezado y las líneas de la factura.
- Creación, edición y eliminación de facturas, solo para clientes de la sucursal y con control de inventario.*

### Corporativo
- Los 10 reportes del Proyecto #1.
- Filtro por sucursal (San José o Limón) o consolidado en los reportes de ventas.
- Estado de la última actualización de cada sucursal y botón para actualizar el resumen.

Nota: * No se pueden eliminar objetos que posean relaciones con otras tablas. Un producto tampoco se puede eliminar si tiene ventas o inventario en alguna sucursal, o si alguna sucursal no responde.

En el Proyecto #2 los clientes y proveedores son solo de consulta, ya que el enunciado indica que el Administrador consulta clientes y proveedores, y sus datos sensibles se encuentran en el Corporativo.
