#!/bin/sh

RES="ki.docset/Contents/Resources/"
DOC="${RES}Documents/"
IDX="${RES}docSet.dsidx"

### clean all up
rm -rf ki.docset
rm -f ki.tgz

### create directory structure
mkdir -p ki.docset/Contents/Resources/Documents/

### copy files
cp files/icon.png ki.docset/icon.png
cp files/Info.plist ki.docset/Contents/Info.plist

### build documentation
jekyll build ki -s ki -d $DOC
rm -f "${DOC}CNAME"

### create sql file
sqlite3 $IDX "CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);"
sqlite3 $IDX "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);"

### fix links & styles
files=( index react api )
for file in ${files[@]}; do
    sed 's/href=\"\//href=\"/g' "${DOC}${file}.html" > tmp
    mv tmp "${DOC}${file}.html"

    sed 's/src=\"\//src=\"/g' "${DOC}${file}.html" > tmp
    mv tmp "${DOC}${file}.html"

    sed 's/<link.*pure-min\.css\">//g' "${DOC}${file}.html" > tmp
    mv tmp "${DOC}${file}.html"
done

### fill index
## react guide
sqlite3 $IDX "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('ReactJS tutorial in ki', 'Guide', 'react.html');"

## try it
sqlite3 $IDX "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('Try ki', 'Guide', 'editor/editor.html');"

## api docs
# categories
grep "h3 id" "${DOC}api.html" | while read -r line; do
    NAME=$(echo $line | sed 's/<h3 id.*>\(.*\)<\/h3>/\1/') 
    LINK="api.html#$(echo $line | sed 's/<h3 id=\"\(.*\)\">.*/\1/')"
    sqlite3 $IDX "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('$NAME', 'Category', '$LINK');"
done

# macros
sed -n '/id=.basics-1/,/id=.literals/p' "${DOC}api.html" | grep "h4 id" | while read -r line; do
    NAME=$(echo $line | sed 's/<h4 id.*><code>\(.*\)<\/code><\/h4>/\1/')
    LINK="api.html#$(echo $line | sed 's/<h4 id=\"\(.*\)\">.*/\1/')"
    sqlite3 $IDX "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('$NAME', 'Macro', '$LINK');"
done

# literals
sed -n '/id=.literals/,/id=.arithmetics/p' "${DOC}api.html" | grep "h4 id" | while read -r line; do
    NAME=$(echo $line | sed 's/<h4 id.*><code>\(.*\)<\/code><\/h4>/\1/')
    LINK="api.html#$(echo $line | sed 's/<h4 id=\"\(.*\)\">.*/\1/')"
    sqlite3 $IDX "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('$NAME', 'Literal', '$LINK');"
done

# functions
sed -n '/id=.functions/,/id=.atoms/p' "${DOC}api.html" | grep "h4 id" | while read -r line; do
    NAME=$(echo $line | sed 's/<h4 id.*><code>\(.*\)<\/code><\/h4>/\1/')
    LINK="api.html#$(echo $line | sed 's/<h4 id=\"\(.*\)\">.*/\1/')"
    sqlite3 $IDX "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('$NAME', 'Function', '$LINK');"
done

# methods
sed -n '/id=.arithmetics/,/id=.functions/p' "${DOC}api.html" | grep "h4 id" | while read -r line; do
    NAME=$(echo $line | sed 's/<h4 id.*><code>\(.*\)<\/code><\/h4>/\1/')
    LINK="api.html#$(echo $line | sed 's/<h4 id=\"\(.*\)\">.*/\1/')"
    sqlite3 $IDX "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('$NAME', 'Method', '$LINK');"
done

sed -n '/id=.atoms/,$ p' "${DOC}api.html" | grep "h4 id" | while read -r line; do
    NAME=$(echo $line | sed 's/<h4 id.*><code>\(.*\)<\/code><\/h4>/\1/')
    LINK="api.html#$(echo $line | sed 's/<h4 id=\"\(.*\)\">.*/\1/')"
    sqlite3 $IDX "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('$NAME', 'Method', '$LINK');"
done


### pack things up
tar --exclude='.DS_Store' -cvzf ki.tgz ki.docset

echo done.
