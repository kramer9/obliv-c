###
### This Makefile is for making the oblivc website only!
###

GITHUB_PAGES_BRANCH=gh-pages
THEME = srg

html:
	hugo --theme=$(THEME)

develop:
	hugo server --theme=$(THEME) --watch

github: html
	cp CNAME public/CNAME
	git add -A 
	git commit -m "Rebuilt site" 
	git push origin master 
	cd ..; git subtree push --force --prefix=web/public https://evansuva@github.com/samee/obliv-c.git gh-pages

.PHONY: html clean develop
