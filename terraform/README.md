# Demo de túneles y agente SSH

Andrés Hernández (@tonejito)
Información

- https://lidsol.org/talk/lpi-openexpo-2020/

Diapositivas

- https://lidsol.org/files/lpi-openexpo-2020-ssh-tonejito.pdf
-

Otros enlaces:

- [Linux Professional Institute en YouTube](https://www.youtube.com/channel/UCEdZMA3it9kp9iwlY9vEYWQ/videos)

## Contenido

- `Makefile`

  - Contiene reglas para crear la infraestructura con `terragrunt` y provisionar las máquinas virtuales con `ansible`

- `ssh_config`

  - Configuración de SSH para todos los ejercicios del demo

- `terraform/`

  - Módulo de terraform para crear la infraestructura del demo
  - Correr con `teragrunt` desde el directorio `terraform/terragrunt`
    - El _estado remoto_ se guardará en `S3`
    - Se creará una tabla en DynamoDB para manejar el _bloqueo de estado_
  - Utilizar el `Makefile`

- `ansible/`

  - Módulo de ansible para provisionar las máquinas virtuales

## Uso

```
$ make terragrunt-init

	...

$ make terragrunt apply

	...

$ make fping

	...

$ make ansible-ping

	...

$ make ansible-playbook

	...

```
