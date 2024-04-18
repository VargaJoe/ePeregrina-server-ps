# Experimental Ebook Server: PowerShell Implementation

## Overview

This project represents an experimental implementation of an ebook server using PowerShell. It explores the capabilities of PowerShell in building server applications. However, it's crucial to note that this implementation is not suitable for production environments. Instead, it serves as a demonstration of PowerShell's potential in server development.

## ePeregrina Ebook Server

The ePeregrina Ebook Server is an experimental project aimed at simulating an ebook server using PowerShell. To get started with this project, follow these steps:

- Clone the repository to your local machine.
- Navigate to the project directory.
- Specify the folders to share in the `settings.json` configuration. These shares appear as main categories on the homepage and provide the basis for URL routing, such as:
"booksPaths" -> /books
"comicsPaths" -> /comics
- Launch the server script using PowerShell.

```powershell
.\program.ps1
```

Note: Any number of categories can be specified, provided they end with the word "Paths". Each category can contain any number of folder paths, specified as string arrays. The current proof of concept solution handles images, TXT, CBZ, EPUB, and ZIP file formats. Depending on browser capabilities, PDF files can also be displayed.

## Rendering logic

The program handles URL requests using `HttpListener`, and URL routing is managed by request handler classes. It includes sample handlers for static files (`staticRequestObject`), MVC-like controllers (`controllerRequestObject`), and custom routing (`ePeregrinaRequestObject`) for an imaginary ebook server. Page rendering is achieved through `.pshtml` files, which are HTML templates with code blocks imitating `.cshtml` files of dotnet. However, instead of C#, PowerShell scripts are used.

## Docker container

The app can be execute in [Docker container](./info/docker.md).
