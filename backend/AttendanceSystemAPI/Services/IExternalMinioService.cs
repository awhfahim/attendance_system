using Minio;

namespace AttendanceSystemAPI.Services;

public interface IExternalMinioService
{
    IMinioClient MinioClient();
}