CUP2PHP=xnj cup2php
PHP2CUP=xnj php2cup_body

%.php: %.in.coffee.php
	$(CUP2PHP) $< $@

%.php.coffee: %.in.php
	$(PHP2CUP) $< $@

%.php: %.in.phpcup
	$(CUP2PHP) $< $@

%.phpcup: %.in.php
	$(PHP2CUP) $< $@

%.out.php: %.phpcup
	$(CUP2PHP) $< $@

%.out.phpcup: %.php
	$(PHP2CUP) $< $@

CUP2HTML=xnj cup2html
HTML2CUP=xnj html2cup

%.html: %.in.coffee.html
	$(CUP2HTML) $< $@

%.html.coffee: %.in.html
	$(HTML2CUP) $< $@

%.html: %.in.htmlcup
	$(CUP2HTML) $< $@

%.htmlcup: %.in.html
	$(HTML2CUP) $< $@

%.out.html: %.htmlcup
	$(CUP2HTML) $< $@

%.out.htmlcup: %.html
	$(HTML2CUP) $< $@

COFFEE=refcoffee

%.js: %.coffee
	$(COFFEE) -pbc $< >$@

COFFEE=refcoffee

%: %.gen.coffee
	$(COFFEE) $< >$@

REFCOFFEE=refcoffee

%.js: %.refcoffee
	$(REFCOFFEE) -pbc $< >$@

JS2COFFEE=js2coffee

%.out.coffee: %.js
	$(JS2COFFEE) $< >$@

%: %.gen.refcoffee
	$(REFCOFFEE) $< >$@

