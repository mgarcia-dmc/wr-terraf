# Implementación de Azure API Management 

-----

## 1\. Resumen del Proyecto

Este repositorio contiene todos los artefactos de código, infraestructura y documentación para el proyecto de **Implementación de Azure API Management (APIM)**.

El objetivo principal es centralizar la administración de las APIs existentes, que actualmente se encuentran en una infraestructura On-Premise, en la plataforma de Azure APIM. Esta implementación permitirá optimizar la gestión, seguridad y monitoreo de las APIs, sentando una base sólida para el crecimiento futuro y la innovación digital.

## 2\. Objetivos Específicos

  * **Centralizar la administración** de 35 APIs On-Premise mediante Azure API Management.
  * **Asegurar alta disponibilidad local** para los servicios API gestionados.
  * **Implementar autenticación segura** utilizando el estándar OAuth2.
  * **Establecer un monitoreo avanzado** del rendimiento y uso de las APIs en tiempo real.
  * **Preparar la infraestructura** de APIs para una escalabilidad futura.

## 3\. Arquitectura de la Solución

La arquitectura propuesta se basa en un modelo Hub-Spoke en Azure, garantizando la seguridad y el aislamiento. Se utilizará un **APIM de Tier Basic**, protegido por un **Application Gateway de entrada (con WAF)**. Para la conexión segura a los servicios On-Premise, se empleará un **segundo Application Gateway como Reverse Proxy de salida** que enrutará el tráfico a través de un **Túnel VPN Site-to-Site**.


## 4\. Cronograma del Proyecto

El proyecto se ejecutará en un cronograma de 14 semanas.

| Fase | Actividad Principal | Semanas | Fechas Estimadas (2025) |
| :--- | :--- | :--- | :--- |
| **F0** | Planificación | S1 | 07 Jul - 11 Jul |
| **F1** | Setup Infra y DEV (15 APIs) | S1 - S5 | 07 Jul - 08 Ago |
| **F2** | Pase a PRD y UAT (15 APIs) | S5 - S8 | 04 Ago - 29 Ago |
| **F3** | Desarrollo DEV (APIs 16-35) | S8 - S10 | 25 Ago - 12 Sep |
| **F4** | Pase a PRD y UAT (APIs 16-35) | S10 - S13 | 08 Sep - 03 Oct |
| **F5** | Capacitación y Cierre | S13 - S14 | 29 Sep - 10 Oct |

## 5\. Equipo del Proyecto

| Puesto | Nombres y Apellidos | Contacto |
| :--- | :--- | :--- |
| Líder técnico | MiguelAngel García | miguel.garcia@e2e.pe |
| Analista Azure | Luis Victor Marquina | luis.marquina@e2e.pe |
| Analista Azure | Jhonatan Jauja | jhonatan.jauja@e2e.pe |
| Jefe de Proyecto | Yericka Ibarra | yericka.ibarra@e2e.pe |
| Responsable de proyectos | Christian Seijas | christian.seijas@e2e.pe |

## 6\. Prerrequisitos para el Inicio

  - [ ] **Acceso a Azure:** Rol "Colaborador" en las suscripciones de Azure para el despliegue de recursos.
  - [ ] **Acceso a DevOps:** Acceso a la organización de Azure DevOps para la creación de repositorios y pipelines.
  - [ ] **Especificaciones de APIs:** Documentación técnica completa de las 35 APIs (Endpoints, métodos, formatos). Se recomienda proveer archivos de especificación OpenAPI (Swagger).
  - [ ] **Información de Dispositivo VPN:** Detalles del dispositivo (router/firewall) VPN On-Premise para la configuración del túnel.
  - [ ] **Disponibilidad de Entornos On-Premise:** Garantizar el correcto funcionamiento de los sistemas backend para las pruebas de conexión.
  - [ ] **Estándares de Nomenclatura:** Aprobar la convención de nombres y etiquetas para los recursos de Azure.

## 7\. Entregables Clave

  * Código Fuente (Infraestructura como Código) y manual de usuario.
  * Plan de pase a producción y evidencia de ejecución.
  * Material de capacitación.
  * Políticas de estándares para la publicación de nuevas APIs y lineamientos de seguridad.

## 8\. Estructura del Repositorio

```
/
├── infra/                  # Plantillas de Infraestructura como Código (Terraform/ARM)
├── pipelines/              # Definiciones de pipelines de CI/CD (YAML)
├── src/                    # Código fuente (ej. políticas de APIM en XML)
├── docs/                   # Documentación del proyecto y diagramas
│   └── Entregables/        # Documentacion presentada
│   └── Analisis/           # Documentacion de analisis y levantamiento de información.
└── ...
```

## 9\. Seguimiento y Comunicación

  * **Seguimiento Semanal:** Reunión de estado del proyecto con el equipo de la U. Wiener.
  * **Status Mensual:** Reunión de seguimiento con los sponsors del proyecto.