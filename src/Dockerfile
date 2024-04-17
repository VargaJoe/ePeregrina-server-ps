FROM mcr.microsoft.com/powershell

RUN mkdir /app
WORKDIR /app
COPY . .

EXPOSE 8888

CMD ["pwsh", "-File", "program.ps1"]