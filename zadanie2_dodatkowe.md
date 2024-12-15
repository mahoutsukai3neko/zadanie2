#Generowanie raportu podatności Trivy
      - name: Generate Trivy Vulnerability Report
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: "fs"
          output: trivy-report.json
          format: json
          scan-ref: .
          exit-code: 0
#Przesyłanie wyników skanowania do GitHub z 30-dniowym okresem przechowywania
      - name: Upload Vulnerability Scan Results
        uses: actions/upload-artifact@v4
        with:
          name: trivy-report
          path: trivy-report.json
          retention-days: 30
#Przerywanie procesu przy wysokich/ krytycznych podatnościach
      - name: Fail build on High/Criticial Vulnerabilities
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: "fs"
          format: table
          scan-ref: .
          severity: HIGH,CRITICAL
          ignore-unfixed: true
          exit-code: 1
          # On a subsequent call to the action we know trivy is already installed so can skip this
          skip-setup-trivy: true
#Budowanie i publikacja obrazu Docker, generowanie danych SBOM i provenance       
      - 
        name: Build and push Docker image
        if: success() 
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          platforms: linux/amd64,linux/arm64
          push: true
          provenance: mode=max
          sbom: true
          cache-from: |
            type=registry,ref=${{ vars.DOCKERHUB_USERNAME }}/cache:latest
          cache-to: |
            type=registry,ref=${{ vars.DOCKERHUB_USERNAME }}/cache:latest  
          tags: ${{ steps.meta.outputs.tags }}
