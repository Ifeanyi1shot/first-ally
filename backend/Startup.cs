using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;  // For IConfiguration

namespace HelloWorldBackend
{
    public class Startup
    {
        private readonly IConfiguration _configuration;

        // Inject IConfiguration into the constructor
        public Startup(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public void ConfigureServices(IServiceCollection services)
        {
            // Optionally add services like MVC, Razor Pages, etc.
            services.AddRouting(); // Add routing services explicitly
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage(); // Developer-specific error page
            }
            else
            {
                app.UseExceptionHandler("/Home/Error"); // Handle errors in production
                app.UseHsts(); // HTTP Strict Transport Security
            }

            app.UseHttpsRedirection(); // Enforce HTTPS
            app.UseRouting(); // Enable routing

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapGet("/", async context =>
                {
                    // Accessing a setting from appsettings.json
                    var connectionString = _configuration.GetConnectionString("DefaultConnection");


                    // Write response with the value from configuration
                    await context.Response.WriteAsync($"Hello, World! From .NET Core Backend. Connection string: {connectionString}");
                });
            });
        }
    }
}
