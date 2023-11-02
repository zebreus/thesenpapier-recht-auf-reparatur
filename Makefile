PWD = $(shell pwd)
ASCIIDOCTOR     = asciidoctor -r asciidoctor-kroki
ASCIIDOCTOR_WEB_PDF = asciidoctor-web-pdf -r asciidoctor-kroki
PYTHON = python3

TARGETS += $(TARGETS_WITHOUT_HTML) index.html
TARGETS_WITHOUT_HTML += $(PROCESSED_CHARTS) $(wildcard scripts/*.adoc)

VEGA_CHART_FILES = $(shell find assets -name '*.vl.json')
VEGA_DATA_FILES = $(addprefix assets/,$(shell grep -Poh "[^\"]+.csv" $(VEGA_CHART_FILES) /dev/null | sort | uniq))
PROCESSED_CHARTS = $(addprefix processed-assets/,$(notdir $(VEGA_CHART_FILES)))

.EXTRA_PREREQS:=Makefile
.PHONY: all pdf preview
all: paper.pdf
preview: paper-preview

SCSS_FILES = $(wildcard styles/*.scss) $(wildcard styles/*/*.scss) $(wildcard styles/*/*/*.scss)

paper.css: $(SCSS_FILES)
	cd styles ; sass --update --sourcemap=none paper.scss:../paper.css

%.html: %.adoc paper.css $(TARGETS_WITHOUT_HTML) $(PROCESSED_CHARTS)
	$(ASCIIDOCTOR) -S unsafe $< -o $@

%-web-preview: %.html
	$(PYTHON) scripts/serve.py $<

%.pdf: %.adoc paper.css $(TARGETS_WITHOUT_HTML) $(PROCESSED_CHARTS)
	$(ASCIIDOCTOR_WEB_PDF) $< -o $@

%-preview: %.adoc paper.css $(TARGETS_WITHOUT_HTML) $(PROCESSED_CHARTS)
	$(ASCIIDOCTOR_WEB_PDF) --preview $<

# Preprocess vega charts
process-charts: $(PROCESSED_CHARTS)

$(PROCESSED_CHARTS) : processed-assets/%.vl.json : assets/%.vl.json $(VEGA_DATA_FILES)
	mkdir -p $(dir $@)
	bash scripts/process_chart.sh $< > $@
	touch $@

# data:
# 	cd experiments && make data
# 	make $(VEGA_DATA_FILES)

# $(ALL_DATA_JSON):
# 	cd experiments && make data

# $(VEGA_DATA_FILES) &: $(ALL_DATA_JSON) data/make_data.sh
# 	bash data/make_data.sh $< data

clean:
	rm -rf 

dist-clean: clean
	rm -rf $(TARGETS)

.PHONY: clean all dist-clean process-charts data