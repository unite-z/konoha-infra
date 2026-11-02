# 0006. Los despliegues abren el Learner Lab si está cerrado

- Estado: aceptado
- Fecha: 2026-11-02
- Ticket: AV-304

## Contexto

La sesión del Learner Lab dura 4 horas y al cerrarse AWS para la EC2. Un merge en `main` con el lab cerrado deja el `deploy-uat` en rojo y hay que relanzarlo a mano (pasó el 2026-11-02 con nueve PR). El lab solo se abre desde el portal de AWS Academy con el usuario de quien lo paga: las credenciales de AWS caducan con la sesión y no sirven para reabrirla.

Los 11 miembros de la organización `unite-z` son administradores, así que un secreto guardado en cualquier repo de la organización lo puede extraer cualquiera con un workflow.

## Decisión

Un repo privado en la cuenta personal del dueño del lab (`Makusoku/abrir-learner-lab`) guarda su usuario y contraseña de AWS Academy y tiene un workflow, `abrir-lab.yml`, que entra con Playwright y pulsa **Start Lab**.

Los repos del equipo solo guardan `LAB_TOKEN`, un token de grano fino que únicamente puede lanzar ese workflow. La acción `.github/actions/asegurar-lab` comprueba el SSH antes de desplegar; si la EC2 no responde, lanza `abrir-lab.yml` y espera hasta 12 minutos.

La regla «ninguna credencial de AWS en GitHub Actions» se mantiene para los repos del equipo: ni la contraseña ni credenciales de AWS entran en ellos.

## Alternativas descartadas

- Contraseña como secreto en `unite-z`: cualquier administrador podría extraerla.
- Encender la EC2 con la API de AWS: las credenciales del lab caducan justo cuando hace falta.
- Esperar y avisar sin abrir el lab: sigue dependiendo de que su dueño esté disponible.

## Consecuencias

- Fusionar con el lab cerrado ya no rompe el despliegue; solo tarda unos minutos más.
- Cada apertura automática consume crédito durante, como mucho, una sesión de 4 horas.
- El login con Playwright depende de la web de AWS Academy y Vocareum: si cambia, `abrir-lab.yml` falla con captura de pantalla y hay que ajustar los selectores.
- Si cambia el dueño del lab, hay que crear su propio repo y su `LAB_TOKEN`.
