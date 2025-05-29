FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base

WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Create the directories with proper permissions
RUN mkdir -p /app/wwwroot/images/attendance && \
    chmod -R 777 /app/wwwroot

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["AttendanceSystemAPI.csproj", "./"]
RUN dotnet restore "AttendanceSystemAPI.csproj"
COPY . .
WORKDIR "/src/"
RUN dotnet build "AttendanceSystemAPI.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "AttendanceSystemAPI.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "AttendanceSystemAPI.dll"]
