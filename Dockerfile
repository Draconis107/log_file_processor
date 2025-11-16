FROM mcr.microsoft.com/powershell:latest AS builder
COPY script.ps1 script.ps1
RUN pwsh -File script.ps1
FROM nginx:alpine
COPY --from=builder report/index.html /usr/share/nginx/html/index.html
CMD ["nginx", "-g", "daemon off;"]