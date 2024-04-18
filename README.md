# Experimental Ebook Server: PowerShell Implementation

## Overview

This project represents an experimental implementation of an as-is ebook server using PowerShell. It aims to explore the capabilities of PowerShell in building server applications, but it is important to note that this implementation is not intended for production use. Instead, it serves as a demonstration of what can be achieved with PowerShell.

## ePeregrina Ebook Server

This is essentially an experiment to see how an ebook server could be simulated in this scripting language. To get started with this project, follow these steps:

- Clone the repository to your local machine.
- Navigate to the project directory.
- Specify the folders to share in the `settings.json`` configuration. These shares appear as main categories on the homepage and provide the basis for URL routing, such as:
"booksPaths" -> /books
"comicsPaths" -> /comics

- Launch the server script using PowerShell.

```powershell
.\program.ps1
```

Note: Any number of categories can be specified, with the condition that they end with the word Paths. Each category can contain any number of folder paths, which should be specified as string arrays. The current proof of concept solution handles image, text, cbz, epub, and zip file formats, and depending on browser capabilities, PDF files can also be displayed.

## Rendering logic

The program handles URL requests using `HttpListener`, and URL routing is managed by request handler classes. There are sample handlers for static files (`staticRequestObject`), MVC-like controllers (`controllerRequestObject`), and custom routing (`ePeregrinaRequestObject`) for an imaginary ebook server. Page rendering is achieved through `.pshtml` files, which are HTML templates with code blocks imitating `.cshtml` files of dotnet, but instead of C#, it uses PowerShell scripts.

## Docker container

The app can be execute in [Docker container](./info/docker.md).


