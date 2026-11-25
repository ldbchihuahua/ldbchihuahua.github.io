# Talentos CUU · Ampayeo y pagos

App web para controlar el cobro del ampayeo por juego: torneos/ligas, peloteros, conceptos de pago, registro de juegos con reparto automático del costo entre los asistentes, marcado de pagos y dashboards (global y por torneo).

URL: https://ldbchihuahua.github.io/talentoscuu/

## Puesta en marcha (una sola vez)

1. **Base de datos**: en Supabase (`muackgffpnpdojzhduuk`) abre *SQL Editor › New query*, pega `schema.sql` y ejecútalo. Crea las tablas `tc_*` con seguridad por roles (RLS).
2. **Llave pública**: ya configurada en `index.html` (`SUPABASE_ANON_KEY`, publishable key).
3. **Correo de confirmación** (opcional): en *Authentication › Sign In / Providers › Email* puedes desactivar "Confirm email" para que las cuentas entren sin confirmar por correo.
4. **Primer acceso**: el primer usuario que se registre con "Solicitar acceso" queda como **admin**. Los siguientes quedan **pendientes** hasta que el admin los activa en la pestaña *Usuarios*.

## Recuperar contraseña

En la pantalla de entrar: *¿Olvidaste tu contraseña?* → llega un correo con un enlace que regresa a la app para crear la contraseña nueva. Requiere en Supabase (*Authentication › URL Configuration*) Site URL `https://ldbchihuahua.github.io/talentoscuu/` y Redirect URL `https://ldbchihuahua.github.io/talentoscuu/**`.

## Roles

| Rol | Puede |
|---|---|
| admin | Todo: torneos, jugadores, conceptos, peloteros por torneo, usuarios, borrar juegos |
| usuario | Ver dashboards, registrar juegos y marcar pagos |
| pendiente | Nada hasta que un admin lo active |

## Campos y tarifas

En la pestaña *Tarifas* se define el costo por **campo + número de ampayers**, general o para un torneo específico. Al registrar un juego el costo se llena así:

1. Tarifa del torneo en ese campo con ese número de ampayers.
2. Si no hay, tarifa general del campo.
3. Si tampoco, el costo base del torneo.

El costo siempre se puede editar, también después de guardar el juego (se vuelve a repartir y se conservan los pagos marcados).

## Instalar

- **Android / PC (Chrome o Edge)**: botón *Instalar* arriba a la derecha, o el ícono de instalar en la barra de direcciones.
- **iPhone / iPad**: en Safari, *Compartir › Agregar a pantalla de inicio* (el botón *Instalar* muestra los pasos).

## Reparto del ampayeo y caja

El costo se divide entre los asistentes y la cuota se **redondea hacia arriba a pesos cerrados** (p. ej. $550 entre 14 = $39.29 → **$40** c/u). Lo que sobra (14 × $40 − $550 = **$10**) va a la **caja**.

- *Caja esperada*: suma de los sobrantes de todos los juegos.
- *Caja acumulada*: la parte del sobrante que ya entró (se cuenta cuando lo cobrado en el juego ya cubrió el ampayeo).

Se muestra en el Dashboard (global y por torneo), en la lista de juegos y en el detalle de cada juego.
