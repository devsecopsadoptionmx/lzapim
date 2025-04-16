# lzapim
project related with lz IaC to deploy APIM

## Actualización: Integración de Redis Cache y Key Vault

### Estructura del archivo Bicep

El archivo `main.bicep` ahora incluye:

1. **Red Virtual (Virtual Network)**: 
   - `vnet-apim` con dos subredes:
     - `SubNet-IntAPIM`: Dirección `10.0.1.0/27`
     - `SubNet-PrivEndAPIM`: Dirección `10.0.2.0/27`

2. **Grupos de Seguridad de Red (NSG)**:
   - `nsg-intapim`: Asociado a `SubNet-IntAPIM`.
   - `nsg-privendapim`: Asociado a `SubNet-PrivEndAPIM`.

3. **API Management (APIM)**:
   - `apim-internal`: Configurado para usar la subred `SubNet-PrivEndAPIM`.
   - **Identidad del sistema**: Se utiliza para acceder al Key Vault.
   - **Integración con Redis Cache**: Configurado para usar Redis como caché.

4. **Azure Key Vault**:
   - `keyvault-standard`: Con acceso restringido a la subred `SubNet-IntAPIM`.
   - Endpoint privado asociado a `SubNet-PrivEndAPIM`.
   - **Permisos RBAC**: La identidad del sistema de APIM tiene el rol `Key Vault Secrets User` asignado.

5. **Azure Redis Cache**:
   - `redis-standard`: Configurado para usar la subred `SubNet-IntAPIM`.
   - Endpoint privado asociado a `SubNet-PrivEndAPIM`.
   - **Integración con APIM**: Redis está configurado como caché para APIM.

6. **Application Insights**:
   - `appinsights`: Para monitoreo de aplicaciones.

### Instrucciones para el despliegue manual

#### Prerrequisitos

1. Tener instalado [Azure CLI](https://learn.microsoft.com/es-es/cli/azure/install-azure-cli).
2. Contar con permisos para crear recursos en una suscripción de Azure.

#### Creación de un Service Principal

Ejecuta el siguiente comando para crear un Service Principal con los permisos necesarios para asignar identidades, permisos sobre Key Vault y Redis, y crear recursos en un grupo de recursos:

```bash
az ad sp create-for-rbac --name "sp-lzapim" \
  --role "Contributor" \
  --scopes /subscriptions/<ID_DE_TU_SUSCRIPCION>/resourceGroups/<NOMBRE_DEL_GRUPO_DE_RECURSOS> \
  --sdk-auth
```

Guarda el resultado del comando, ya que contiene las credenciales necesarias para autenticarse.

> Nota: El rol `Contributor` otorga permisos para crear recursos, asignar identidades y configurar permisos en Key Vault y Redis dentro del grupo de recursos especificado.

#### Validación del archivo Bicep

Antes de desplegar, puedes validar el archivo Bicep para asegurarte de que no haya errores de sintaxis o problemas en la estructura. Ejecuta el siguiente comando:

```bash
az bicep build --file IaC/main.bicep
```

Este comando compilará el archivo Bicep y generará un archivo ARM JSON equivalente si no hay errores.

#### Despliegue del archivo Bicep

1. Autentícate en Azure usando el Service Principal:

```bash
az login --service-principal -u <APP_ID> -p <PASSWORD> --tenant <TENANT_ID>
```

2. Despliega el archivo Bicep utilizando el archivo de parámetros:

```bash
az deployment group create \
  --name despliegue-lzapim \
  --resource-group <NOMBRE_DEL_GRUPO_DE_RECURSOS> \
  --template-file IaC/main.bicep \
  --parameters @IaC/main.parameters.json
```

Reemplaza `<NOMBRE_DEL_GRUPO_DE_RECURSOS>` con el nombre del grupo de recursos.
