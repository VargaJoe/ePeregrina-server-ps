
## Xpdf and XpdfReader

The Xpdf open source project includes a PDF viewer along with a collection of command line tools which perform various functions on PDF files. Peregrina webserver uses `pdftohtml` and `pdfimages` to create cover or thumbnail images and preprocessed html pages. 

The executable files need to be downloaded from the official page of Xpdf and placed under the `tools` folder set in settings, eg.:

```json
 "toolsFolder": "./tools",
 ```

[Official XpdfReader download page](https://www.xpdfreader.com/download.html)