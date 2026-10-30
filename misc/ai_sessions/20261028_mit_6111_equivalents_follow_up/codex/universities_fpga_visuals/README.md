# Illustrated university FPGA reports

- [English illustrated report](../universities_fpga_curricula_illustrated.html)
- [Russian illustrated report](../universities_fpga_curricula_illustrated_ru.html)
- [Figure download index](index.html)

There are eight figures in each language, each exported as SVG and PNG: a seven-area criteria atlas, a pipeline/verification illustration, a stacked university ranking, an area-profile heatmap, coverage counts for all 49 criteria, a regional comparison, a world sample map, and a map of the former Soviet republics. The HTML editions embed their SVG images and can display them without a network connection or a separate image folder. Download links need this folder. The original reports and all their scoring data are unchanged.

## Interpretation

The evidence snapshot is 29 October 2026. All counts come from the existing report files, not new university research. The ranking chart shows all 14 universities with at least four verified criteria, retaining ties; the full report still contains all 90 universities. The two cross-university programs are displayed separately. Criterion-frequency charts exclude both programs. A criterion is counted once per university, even if several sources establish it. Hatched portions distinguish support based only on the requested UVM scoring convention.

The heatmap normalizes each area by its own maximum (9, 6, 11, 6, 7, 7, 3); the labels give exact subtotals. The ranking bars use the full 49-point scale. Regional figures reproduce the original sample means and include records with no verified points; they do not estimate national education quality. Zero verified points does not establish absence of teaching.

The world map uses five representative regional anchors and scales circle area by sample size. The Eurasia map uses representative country anchors, not campus coordinates, and covers the 52 universities attributed to 15 former Soviet republics in the country table. Two separately attributed campuses are included in the original regional total of 54 but excluded from this country map. Both programs are excluded from geographic statistics. Country names use local languages. Country anchors, label positions and all plotted statistics are retained in the generator/data files.

The pipeline illustration is conceptual, not timing-accurate RTL and not evidence for any particular university. It depicts an elastic arithmetic path, finite buffering, accepted-transaction monitoring, a reference model and a scoreboard. Detailed implementation constraints must be established in the actual RTL exercise.

## Map source and reproducibility

Basemap: [Natural Earth](https://www.naturalearthdata.com/), 1:110m countries from the [maintainer's GeoJSON repository](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_110m_admin_0_countries.geojson). Natural Earth makes the data available in the [public domain](https://www.naturalearthdata.com/about/terms-of-use/). Boundaries follow that dataset; the maps are geographical summaries. The archived GeoJSON and its checksum are stored with the research files and `provenance.json`. The projection is equirectangular; circle areas, rather than land areas, encode sample sizes.

The figures use Matplotlib 3.9.4 and local DejaVu/Droid font fallbacks. PNG exports are 160 dpi; SVG exports retain vector geometry and text. The local Python environment is isolated at `universities_fpga_curricula_research/.visuals_venv`.

Rebuild from `/home/verilog/codex`:

```text
universities_fpga_curricula_research/.visuals_venv/bin/python universities_fpga_curricula_research/build_visuals.py
python3 universities_fpga_curricula_research/build_illustrated_reports.py
python3 universities_fpga_curricula_research/validate_illustrated.py
```

`figures.json` describes the assets. `chart_data.json` contains plotted values, selected institutions and denominators. The full evidence remains in the reports and their linked ledger. The enlargement control works locally, including in the embedded-image editions.
