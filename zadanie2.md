# zadanie2

To repozytorium zawiera workflow GitHub Actions, który buduje obraz Docker dla dwóch architektur (amd64 i arm64), używa cache, i testuje obraz pod kątem podatności na zagrożenia za pomocą Docker Scout.

Workflow jest zdefiniowany w pliku `.github/workflows/ci_obowiazkowa.yml` i obejmuje następujące kroki: 
#Sprawdzenie kodu 
- 
        name: Check out the source_repo
        uses: actions/checkout@v4
#Konfiguracja QEMU dla wieloplatformowych buildów 
 - 
        name: QEMU set-up
        uses: docker/setup-qemu-action@v3
#Konfiguracja Docker Buildx 
- 
        name: Buildx set-up
        uses: docker/setup-buildx-action@v3
#Logowanie do Docker Hub
- 
        name: Login to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ vars.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }} 
#Budowanie obrazu Docker 
- 
        name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          platforms: linux/amd64,linux/arm64
          push: false
          cache-from: |
            type=registry,ref=${{ vars.DOCKERHUB_USERNAME }}/cache:latest
          cache-to: |
            type=registry,ref=${{ vars.DOCKERHUB_USERNAME }}/cache:latest  
          tags: ${{ steps.meta.outputs.tags }}
#Skanowanie obrazu pod kątem podatności za pomocą Docker Scout 
- name: Docker Scout
        id: docker-scout
        if: ${{ github.event_name == 'pull_request' }}
        uses: docker/scout-action@v1
        with:
          command: compare
          image: ${{ steps.meta.outputs.tags }}
          to: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.COMPARE_TAG }}
          ignore-unchanged: true
          only-severities: critical,high
          write-comment: true
          github-token: ${{ secrets.GIT_TOKEN }} 
#Analiza krytycznych i wysokich CVE 
- name: Analyze for critical and high CVEs
        id: docker-scout-cves
        if: ${{ github.event_name != 'pull_request_target' }}
        uses: docker/scout-action@v1
        with:
          command: cves
          image: ${{ steps.meta.outputs.tags }}
          sarif-file: sarif.output.json
          summary: true
#Przesyłanie wyników SARIF 
- name: Upload SARIF result
        id: upload-sarif
        if: ${{ github.event_name != 'pull_request_target' }}
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: sarif.output.json
#Push obrazu Docker do GitHub, jeśli nie znaleziono krytycznych ani wysokich podatności
- name: Push Docker image to GitHub Container Registry
        if: ${{ success() && steps.docker-scout-cves.outputs.critical_cves == 'false' && steps.docker-scout-cves.outputs.high_cves == 'false' }}
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          platforms: linux/amd64,linux/arm64
          push: true
          cache-from: |
            type=registry,ref=ghcr.io/${{ github.repository }}:cache/latest 
          cache-to: |
            type=registry,ref=ghcr.io/${{ github.repository }}:cache/latest  
          tags: ${{ steps.meta.outputs.tags }}

#Secrets wymagane dla workflow: GIT_TOKEN, DOCKERHUB_TOKEN

#Variables wymagane dla workflow: DOCKERHUB_USERNAME

#Definicja zmienych środowiskowych
env:
  REGISTRY: docker.io
  IMAGE_NAME: ${{ github.repository }}
  SHA: ${{ github.event.pull_request.head.sha || github.event.after }}
  COMPARE_TAG: latest

#Workflow uruchamia się przy pushu tagów zaczynających się od 'v'
on:
  workflow_dispatch:
  push:
    tags:
    - 'v*'