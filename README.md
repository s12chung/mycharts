# mycharts

My personal helm charts. Add a chart to the `charts` directory and run:

```bash
CHART=chartname make
```

To use the charts:

```bash
helm repo add mycharts https://s12chung.github.io/mycharts/charts
helm repo update
helm install mycharts/chartname
```
