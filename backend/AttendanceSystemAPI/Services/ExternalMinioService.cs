using AttendanceSystemAPI.Options;
using Microsoft.Extensions.Options;
using Minio;

namespace AttendanceSystemAPI.Services;

public class ExternalMinioService : IExternalMinioService
{
    private readonly IMinioClient _minioClient;

    public ExternalMinioService(IOptions<MinioOptions> minioOptions)
    {
        var options = minioOptions.Value;
        
        ArgumentNullException.ThrowIfNull(options.ExternalEndpoint);
        ArgumentNullException.ThrowIfNull(options.AccessKey);
        ArgumentNullException.ThrowIfNull(options.SecretKey);
        
        _minioClient = new MinioClient()
            .WithEndpoint(options.ExternalEndpoint)
            .WithCredentials(options.AccessKey, options.SecretKey)
            .WithSSL(false);
    }
    public IMinioClient MinioClient()
    {
        return _minioClient;
    }
}