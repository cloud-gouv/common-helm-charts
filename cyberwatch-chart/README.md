# Helm Chart

Ce projet contient le chart Helm nécessaire au déploiement de Olympe sur un cluster Kubernetes.

## Tests

Les tests de génération des templates sont effectués à l'aide du script `spec/test-charts.sh`. Il est nécessaire d'avoir la commande `helm` pour tester le chart :

Installation de la CLI `Helm` : https://helm.sh/fr/docs/intro/install/#%C3%A0-partir-des-releases-binaires

De préférence, utilisez une image docker :

``` sh
# Être à la racine du projet helm-chart
docker run --rm --user=$(id -u) --workdir=/helm-chart --volume=$(pwd):/helm-chart harbor.cyberwatch.fr/public/dtzar/helm-kubectl spec/test-charts.sh
```
