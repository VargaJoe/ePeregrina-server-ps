# Experimental PowerShell Implementation of an Ebook Server

This app is an experimental PowerShell implementation of an as is ebook server. It is not intended for production environments; rather, it's a playful development project that pushes the boundaries of PowerShell.

## ePeregrina ebook server

Ez valójában kísérletezés, miképp lehetne ebook szervert imitálni ebben a script nyelvben. Az indítás előtt meg kell adni a megosztani kívánt mappákat a `settings.json` beállításai között. Ezek a megosztások főkategóriaként jelennek meg a főoldalon, illetve ez adja az url routing alapját, mint például:
"booksPaths" -> /books
"comicsPaths" -> /comics

Tetszőleges számú kategória adható meg, a feloldás feltétele, hogy `Paths` szóra végződjön. Minden kategória tetszőleges számú mappa útvonalat tartalmazhat, melyeket string tömbként kell megadni. A jelenlegi proof of concept megoldás kép, szöveg, cbz, epub és zip formátumú fájlokat kezel, illetve böngésző lehetőségeitől függően pdf kiterjesztésű file-ok is megjeleníthetők.

## Rendering logic

A program 
It handle url requests by HttpListener and url routing is handled by requesthandler classes. There are sample handlers for static files (`staticRequestObject`), mvc like controllers (`controllerRequestObject`) and custom routing (`ePeregrinaRequestObject`) for an imaginary ebook server, where Page rendering is made through by `.pshtml` files which are html templates with code blocks imitating `.cshtml` of dotnet, but instead c# it uses powershell scripts.

## Docker container

The app can be execute in [Docker container](./info/docker.md).


