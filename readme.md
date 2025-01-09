# Cloud Architecture, Network Setup, and Cost Optimization Strategies

## 1. **Cloud Architecture Overview**

### Components

1. **Flutter Mobile App**
   - Built and tested in the CI/CD pipeline.
   - Artifacts stored for deployment to app stores.

2. **.NET Core Backend**
   - Hosted on Azure App Services.
   - Connected to a managed Azure SQL Database.
   - Secured within a Virtual Private Cloud (VPC) using subnet segregation.

3. **React Web-Based Back-Office Application**
   - Deployed to Azure Static Web Apps.
   - Integrated with the .NET Core Backend API.

### Architecture Diagram
```text
                +---------------------------+
                |       User Devices        |
                |   (Mobile, Web Browser)   |
                +------------+--------------+
                             |
                             v
+---------------------------+---------------------------+
|                     Azure Front Door                   |
|      (HTTPS with Load Balancing & WAF Protection)      |
+---------------------------+---------------------------+
                /                                \
+---------------------------+          +---------------------------+
|    React Web Application  |          |     .NET Core Backend    |
|   (Azure Static Web App)  |          | (Azure App Services)      |
+---------------------------+          +---------------------------+
                                                    |
                                           +------------------+
                                           | Managed SQL DB   |
                                           | (Azure SQL)      |
                                           +------------------+
```

---

## 2. **Network Setup**

### Virtual Private Cloud (VPC)
- **Backend and Database**:
  - Deployed within a private subnet in Azure VPC.
  - Restricted inbound and outbound traffic using NSGs (Network Security Groups).

### Load Balancer
- **Azure Front Door**:
  - Routes traffic to React frontend and backend instances.
  - Ensures secure HTTPS communication and load balancing.
  - Includes Web Application Firewall (WAF) for enhanced security.

### Security Measures
- **TLS/SSL Certificates**:
  - Enabled for HTTPS connections via Azure Front Door.
- **Firewall Rules**:
  - Only allows specific IP ranges to access the database.
  - Blocks all traffic to private subnets except through approved load balancers.

---

## 3. **Cost Optimization Strategies**

### Cloud Services
- **Azure App Services**:
  - Autoscaling configured for the backend.
  - Uses reserved instances for predictable workloads.

- **Azure SQL Database**:
  - Tiered pricing model based on resource consumption.
  - Scales automatically during peak loads.

- **Azure Static Web Apps**:
  - Cost-efficient hosting for the React frontend.

### Autoscaling
- Configured for both the backend and web application:
  - Scales based on CPU usage and request latency.
  - Minimum and maximum instance thresholds set to manage costs.

### Budget Alerts
- Set up in the Azure Portal:
  - Alerts configured for monthly cloud spend.
  - Notifications sent to the operations team for budget threshold breaches.

---

## 4. **Logging and Monitoring Setup**

### Logging
- **Flutter Mobile App**:
  - Logs captured using Firebase Crashlytics for performance and error reporting.

- **React Web App**:
  - Application logs sent to Azure Monitor Application Insights.

- **.NET Core Backend**:
  - Logs captured via Serilog and sent to Azure Log Analytics.

### Monitoring
- **Prometheus + Grafana**:
  - Prometheus scrapes metrics from:
    - .NET Core backend: Response times, API error rates.
    - React frontend: Page load times, error rates.

- **Grafana Dashboards**:
  - Visualizes key metrics:
    - Response time.
    - Error rates.
    - CPU/Memory usage.

### Instructions for Accessing Grafana Dashboard
1. **Deploy Prometheus and Grafana**:
   - Prometheus configuration:
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

   - Run Grafana:
     ```sh
     docker run -d -p 3000:3000 grafana/grafana
     ```

2. **Access Dashboard**:
   - Open Grafana at `http://<server-ip>:3000`.
   - Import JSON configuration to set up the dashboard.

---

## 5. **Deployment Strategy and Rollbacks**

### Deployment Strategy
- **Blue-Green Deployment**:
  - Deploy new versions to a separate environment.
  - Test the new environment before switching traffic.

- **Canary Deployment**:
  - Gradually shift traffic to new deployments while monitoring performance.

### Rollback Procedures
- **Automatic Rollbacks**:
  - Integrated into CI/CD pipelines.
  - Deployments fail if health checks do not pass.

- **Manual Rollbacks**:
  - Switch traffic back to the previous version using Azure Front Door.
  - Retain backups of the previous deployment artifacts for restoration.

---

## 6. **Conclusion**
This documentation provides a comprehensive overview of the cloud architecture, network setup, cost optimization strategies, logging and monitoring, and deployment strategies implemented for the investment banking application. The setup ensures scalability, security, and reliability while maintaining cost efficiency.
