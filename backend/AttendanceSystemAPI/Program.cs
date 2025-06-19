using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using AttendanceSystemAPI.Data;
using AttendanceSystemAPI.Options;
using AttendanceSystemAPI.Services;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Minio;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add CORS configuration for Flutter mobile app and web
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp", policy =>
    {
        // Allow specific origins for web and all for mobile
        policy.WithOrigins(
                "http://localhost:3000",        // Flutter web dev
                "http://127.0.0.1:3000",       // Alternative localhost
                "https://ola-fahim.duckdns.org", // Production domain
                "http://localhost:5070",        // Local API access
                "http://127.0.0.1:5070",       // Alternative localhost API
                "http://10.0.2.2:5070",        // Android emulator
                "capacitor://localhost",        // Capacitor apps
                "ionic://localhost",            // Ionic apps
                "http://localhost",             // General localhost
                "https://localhost"             // HTTPS localhost
              )
              .SetIsOriginAllowed(_ => true)    // Allow mobile apps (they don't send Origin)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials()
              .WithExposedHeaders("*");
    });
    
    // Add a permissive policy for development
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Add Entity Framework with In-Memory Database
builder.Services.AddDbContext<AttendanceDbContext>(options =>
    options.UseInMemoryDatabase("AttendanceSystemDb"));

// Add JWT Service
builder.Services.AddScoped<JwtService>();

// Configure JWT Authentication
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = jwtSettings["SecretKey"] ?? "YourSuperSecretKeyThatShouldBeAtLeast32CharactersLong!";
var key = Encoding.ASCII.GetBytes(secretKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false; // Caddy handles SSL termination
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidateAudience = true,
        ValidAudience = jwtSettings["Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddOptions<MinioOptions>()
    .BindConfiguration(MinioOptions.SectionName)
    .ValidateDataAnnotations()
    .ValidateOnStart();
        
var configuration = builder.Configuration;
var minioAccessKey = configuration.GetRequiredSection(MinioOptions.SectionName)
    .GetValue<string>(nameof(MinioOptions.AccessKey));
var minioSecretKey = configuration.GetRequiredSection(MinioOptions.SectionName)
    .GetValue<string>(nameof(MinioOptions.SecretKey));
var endpoint = configuration.GetRequiredSection(MinioOptions.SectionName)
    .GetValue<string>(nameof(MinioOptions.Endpoint));
        
ArgumentNullException.ThrowIfNull(minioAccessKey);
ArgumentNullException.ThrowIfNull(minioSecretKey);
ArgumentNullException.ThrowIfNull(endpoint);

if (configuration.GetValue<bool>("DOTNET_RUNNING_IN_CONTAINER"))
{
    var dockerEndpoint = configuration.GetRequiredSection(MinioOptions.SectionName)
        .GetValue<string>(nameof(MinioOptions.DockerEndpoint));
            
    endpoint = dockerEndpoint;
}
        
builder.Services.AddMinio(options =>
{
    options.WithEndpoint(endpoint)
        .WithCredentials(minioAccessKey, minioSecretKey)
        .WithSSL();
});
        
builder.Services.TryAddScoped<IFileStorageService, MinioService>();
builder.Services.TryAddSingleton<IExternalMinioService, ExternalMinioService>();

var app = builder.Build();

// Ensure database is created and seeded
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AttendanceDbContext>();
    context.Database.EnsureCreated();
}

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    // Use more permissive CORS in development
    app.UseCors("AllowAll");
}
else
{
    app.UseCors("AllowAll");
    // Use specific CORS policy in production
    app.UseCors("AllowFlutterApp");
}

// Add additional headers for mobile apps
app.Use(async (context, next) =>
{
    // Add CORS headers manually for mobile apps that might not send preflight requests
    context.Response.Headers.Add("Access-Control-Allow-Origin", "*");
    context.Response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    context.Response.Headers.Add("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
    context.Response.Headers.Add("Access-Control-Expose-Headers", "*");
    
    // Handle preflight requests
    if (context.Request.Method == "OPTIONS")
    {
        context.Response.StatusCode = 200;
        return;
    }
    
    await next();
});

// Enable static file serving for images
app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
