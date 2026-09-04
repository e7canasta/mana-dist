# Playbook: validacion desde cero

1. Crear un directorio temporal fuera del workspace habitual.
2. Clonar `mana-dist`.
3. Ejecutar `bootstrap.sh` y comprobar los commits fijados.
4. Probar `build.sh` y el perfil dev.
5. Ejecutar el seed y validar UI/API.
6. Fabricar una release.
7. Eliminar solo contenedores e imagenes de prueba.
8. Instalar el tarball en otro directorio.
9. Levantar produccion y repetir las validaciones.

No borrar volumenes de datos sin una orden explicita.
