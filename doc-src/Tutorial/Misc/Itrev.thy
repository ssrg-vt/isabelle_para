Itrev = Main +
consts itrev :: 'a list => 'a list => 'a list
primrec
"itrev []     ys = ys"
"itrev (x#xs) ys = itrev xs (x#ys)"
end
