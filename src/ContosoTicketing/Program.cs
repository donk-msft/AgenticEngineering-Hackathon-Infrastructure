using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApplicationInsightsTelemetry();

var app = builder.Build();

// Passwordless connection string supplied by infra/modules/webapp.bicep as
// ConnectionStrings__Default. Authentication uses the app's managed identity.
string? ConnectionString() => app.Configuration.GetConnectionString("Default");

// Liveness probe used by the App Service health check (healthCheckPath: /healthz).
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy" }));

// Readiness probe: fails when the private endpoint, the private DNS zone or the
// managed identity grant is broken. This is the signal the Azure SRE Agent
// investigates in expert lab 4.
app.MapGet("/readyz", async (ILogger<Program> logger, CancellationToken cancellationToken) =>
{
    var connectionString = ConnectionString();
    if (string.IsNullOrWhiteSpace(connectionString))
    {
        logger.LogError("ConnectionStrings__Default is not configured.");
        return Results.Problem("Ticket store is not configured.", statusCode: StatusCodes.Status503ServiceUnavailable);
    }

    try
    {
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = new SqlCommand("SELECT 1", connection);
        await command.ExecuteScalarAsync(cancellationToken);
        return Results.Ok(new { status = "ready", database = "reachable" });
    }
    catch (SqlException ex)
    {
        logger.LogError(ex, "Readiness probe failed: the ticketing database is unreachable.");
        return Results.Problem("The ticketing database is unreachable.", statusCode: StatusCodes.Status503ServiceUnavailable);
    }
});

// The business route. Returns HTTP 500 when the database cannot be queried,
// which is the reproducible fault used by expert lab 4.
app.MapGet("/api/tickets", async (ILogger<Program> logger, CancellationToken cancellationToken) =>
{
    var connectionString = ConnectionString();
    if (string.IsNullOrWhiteSpace(connectionString))
    {
        logger.LogError("ConnectionStrings__Default is not configured.");
        return Results.Problem("Ticket store is not configured.", statusCode: StatusCodes.Status500InternalServerError);
    }

    try
    {
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        // Parameterised on purpose: never concatenate input into SQL text.
        await using var command = new SqlCommand(
            "SELECT TOP (@take) Id, Title, Status FROM dbo.Tickets ORDER BY Id DESC",
            connection);
        command.Parameters.AddWithValue("@take", 20);

        var tickets = new List<object>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            tickets.Add(new
            {
                id = reader.GetInt32(0),
                title = reader.GetString(1),
                status = reader.GetString(2)
            });
        }

        return Results.Ok(tickets);
    }
    catch (SqlException ex)
    {
        logger.LogError(ex, "Failed to read tickets from the ticketing database.");
        return Results.Problem("Failed to read tickets.", statusCode: StatusCodes.Status500InternalServerError);
    }
});

app.Run();
