# DevOps Architecture and Documentation

## Cloud Architecture Overview

### Architecture Diagram
Below is the architecture diagram representing the deployment of the Flutter mobile app, .NET Core backend, and React web-based back-office application:

```
            [Users]
               |
               v
        [Azure Front Door]
               |
       +-------+-------+
       |               |
[React App Service] [Backend App Service]
               |
       [Azure SQL Database]
               |
[Managed Backups, Read Replicas]
```

### Components
1. **Frontend (React Web Application)**
   - Deployed on Azure App Service.
   - HTTPS-enabled with a custom domain.
   - Integrated with Azure Front Door for load balancing and global distribution.

2. **Backend (.NET Core)**
   - Deployed on Azure App Service.
   - Exposed via HTTPS and protected with Azure Application Gateway.
   - Connected to an Azure SQL Database for secure and scalable data storage.

3. **Database**
   - Managed Azure SQL Database.
   - Automated backups with retention policies and read replicas for performance optimization.

4. **Mobile App (Flutter)**
   - Built using the CI/CD pipeline, APK generated, and made available for distribution.

---

## Networking Setup

### Virtual Private Cloud (VPC)
A VPC is configured to ensure secure communication within the backend and database layers:

- **Subnets:**
  - Public Subnet: Contains the load balancers (Azure Front Door, Application Gateway).
  - Private Subnet: Hosts the backend App Service and database.

- **Security Groups:**
  - Allow inbound traffic on HTTPS (port 443) to the frontend and backend.
  - Restrict database access to backend App Service IPs only.

### Load Balancer
Azure Front Door is used for traffic distribution:
- Routes traffic to the React frontend and .NET Core backend.
- Automatically scales based on demand.
- Ensures HTTPS communication with SSL/TLS certificates.

---

## Cost Optimization Strategies

### Services
1. **Azure App Services (Frontend and Backend):**
   - Enable autoscaling based on CPU/memory utilization.
   - Use lower-cost tiers (e.g., B1/B2) in development environments.

2. **Database Optimization:**
   - Use Azure SQL’s scaling features for adjusting compute/storage.
   - Implement caching to reduce database load.

3. **Budget Alerts:**
   - Set budget alerts in Azure to monitor spending.
   - Alerts trigger at 80%, 90%, and 100% usage.

4. **Auto-scaling:**
   - Configure autoscaling rules to handle traffic spikes without over-provisioning resources.

---

## Logging and Monitoring

### Prometheus + Grafana Setup

#### Prometheus
1. **Setup:**
   - Install Prometheus and configure the `prometheus.yml` file:
     ```yaml
     global:
       scrape_interval: 15s

     scrape_configs:
       - job_name: 'backend'
         static_configs:
           - targets: ['backend-app:80']

       - job_name: 'frontend'
         static_configs:
           - targets: ['frontend-app:80']
     ```

2. **Run Prometheus:**
   ```sh
   prometheus --config.file=prometheus.yml
   ```

#### Grafana
1. **Setup:**
   - Install Grafana and connect it to Prometheus as a data source.

2. **Import Dashboard:**
   - Use the provided `grafana.dashboards.json` to import a custom dashboard:
     - Navigate to `Dashboard > Import`.
     - Paste the JSON content and click **Load**.

3. **Key Metrics Monitored:**
   - Backend Response Time: `http_request_duration_seconds`.
   - Frontend Error Rate: `rate(http_errors_total[1m])`.
   - Resource Utilization: CPU, Memory usage.

4. **Alerts:**
   - Configure alerts in Grafana for downtime, high error rates, or resource utilization thresholds.

---

## Deployment Strategy and Rollbacks

### Deployment Strategy
1. **Blue-Green Deployment:**
   - Create two environments (blue and green).
   - Deploy new versions to the green environment.
   - Perform health checks.
   - Switch traffic to green if successful.

2. **Canary Deployment (Optional):**
   - Gradually route traffic to the new version to test stability.

### Rollback Procedures
1. **Automated Rollbacks:**
   - The CI/CD pipeline includes health checks.
   - If health checks fail:
     - Automatically roll back to the last stable version.
     - Notify the team via email/slack integrations.

2. **Manual Rollbacks:**
   - Re-deploy the last stable build using pipeline triggers.

---

## Detailed CI/CD Pipeline Instructions

### Mobile App (Flutter)
1. Install dependencies:
   ```yaml
   - name: Install Dependencies
     run: flutter pub get
   ```
2. Build APK:
   ```yaml
   - name: Build APK
     run: flutter build apk
   ```

### Backend (.NET Core)
1. Build and Test:
   ```yaml
   - name: Build Backend
     run: dotnet build

   - name: Run Unit Tests
     run: dotnet test
   ```
2. Deploy to Azure App Service:
   ```yaml
   - name: Deploy to Azure
     uses: azure/webapps-deploy@v2
     with:
       app-name: '<your-backend-app-name>'
       slot-name: 'production'
   ```

### Frontend (React)
1. Build and Test:
   ```yaml
   - name: Install Dependencies
     run: npm install

   - name: Run Tests
     run: npm test

   - name: Build Frontend
     run: npm run build
   ```
2. Deploy to Azure App Service:
   ```yaml
   - name: Deploy to Azure
     uses: azure/webapps-deploy@v2
     with:
       app-name: '<your-frontend-app-name>'
       slot-name: 'production'
   ```

---

## Accessing the Monitoring Dashboard
1. Open Grafana at [http://localhost:3000](http://localhost:3000) (if local) or your public IP (cloud).
2. Login credentials:
   - **Username:** `admin`
   - **Password:** `admin` (default, change it immediately).
3. Navigate to your imported dashboard to view metrics and alerts.
