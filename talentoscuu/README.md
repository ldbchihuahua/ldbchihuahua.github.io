# Talentos CUU · Ampayeo y pagos

App web para controlar el cobro del ampayeo por juego: torneos/ligas, peloteros, conceptos de pago, registro de juegos con reparto automático del costo entre los asistentes, marcado de pagos y dashboards (global y por torneo).

URL: https://ldbchihuahua.github.io/talentoscuu/

## Puesta en marcha (una sola vez)

1. **Base de datos**: en Supabase (`muackgffpnpdojzhduuk`) abre *SQL Editor › New query*, pega `schema.sql` y ejecútalo. Crea las tablas `tc_*` con seguridad por roles (RLS).
2. **Llave pública**: copia la *anon public key* (*Project Settings › API*) en `SUPABASE_ANON_KEY` dentro de `index.html`. Si no se pone, la app la pide al abrirse y la guarda en ese navegador.
3. **Correo de confirmación** (opcional): en *Authentication › Sign In / Providers › Email* puedes desactivar "Confirm email" para que las cuentas entren sin confirmar por correo.
4. **Primer acceso**: el primer usuario que se registre con "Solicitar acceso" queda como **admin**. Los siguientes quedan **pendientes** hasta que el admin los activa en la pestaña *Usuarios*.

## Roles

| Rol | Puede |
|---|---|
| admin | Todo: torneos, jugadores, conceptos, peloteros por torneo, usuarios, borrar juegos |
| usuario | Ver dashboards, registrar juegos y marcar pagos |
| pendiente | Nada hasta que un admin lo active |

## Reparto del ampayeo

El costo se divide entre los peloteros marcados como asistentes. Se reparte en centavos para que la suma cuadre exacto (p. ej. $1,000 entre 6 = 4 × $166.67 + 2 × $166.66).
