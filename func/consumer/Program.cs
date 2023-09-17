using CloudNative.CloudEvents.Http;
using CloudNative.CloudEvents.SystemTextJson;
using CloudNative.CloudEvents.AspNetCore;
using System.Text.Json.Serialization;
using System.Text.Json;
using System.Text.Json.Serialization.Metadata;

var builder = WebApplication.CreateBuilder(args);
// required to do AOT with option 2:
builder.Services.ConfigureHttpJsonOptions(options => options.SerializerOptions.TypeInfoResolverChain.Add(MyJsonContext.Default));
var app = builder.Build();

app.MapGet("/", () => "Consumer is running!");

var delay = app.Configuration.GetValue<int>("DelayInMs", 0);
var failMessage = app.Configuration.GetValue<string>("FailMessage", "<fail>")!;
var failFrequency = app.Configuration.GetValue<int>("FailFrequency", 0) % 100;
app.Logger.LogInformation($"Delay is {delay}ms, fail message is '{failMessage}' and frequency is {failFrequency}%.");
var formatter = new JsonEventFormatter<Message>(new JsonSerializerOptions { TypeInfoResolver = JsonTypeInfoResolver.Combine(MyJsonContext.Default) }, default);
var random = new Random();

// option 1, binding to `Event` to get `CloudEvent`
app.MapPost("/receive/", (Event @event, ILogger<Program> logger) =>
{
    var execNumber = Interlocked.Increment(ref count);
    var cloudEvent = @event.CloudEvent;
    if (cloudEvent is null)
    {
        logger.LogWarning("Got empty cloud event.");
        return Results.BadRequest("Got empty cloud event.");
    }
    if (cloudEvent.Data is null)
    {
        logger.LogWarning("Got empty data.");
        return Results.BadRequest("Got empty data.");
    }
    else if (cloudEvent.Data is Message message)
    {
        logger.LogInformation($"{execNumber:000}: Received message: {message.Value}, id: {cloudEvent.Id}, type: {cloudEvent.Type}, source: {cloudEvent.Source}, subject: {cloudEvent.Subject}, time: {cloudEvent.Time}, spec version: {cloudEvent.SpecVersion.VersionId}, data schema: {cloudEvent.DataSchema?.ToString() ?? "null"}, data content type: {cloudEvent.DataContentType}");
        if (message.Value.IndexOf(failMessage) > -1 || random.Next(100) <= failFrequency)
        {
            logger.LogError($"Failing message: {message.Value}");
            return Results.Content($"Failing message: {message.Value}", "text/plain", statusCode: 500);
        }
    }
    else
    {
        logger.LogWarning($"Got unexpected message. Type: {cloudEvent.Data.GetType().FullName}. Details: {cloudEvent.Data}.");
    }
    if (delay > 0)
    {
        logger.LogInformation($"Sleeping for {delay} ms...");
        Thread.Sleep(delay);
    }
    return Results.Ok();
});

// option 2, binding directly to `Message` type
app.MapPost("/receive2/", (Message message, ILogger<Program> logger) =>
    logger.LogInformation($"receive2: Received message: {message.Value}"));

// option 3, binding to `CloudEvent` with `HttpRequest.ToCloudEventAsync`
app.MapPost("/deadletter/", async (HttpRequest request, ILogger<Program> logger) =>
{
    var execNumber = Interlocked.Increment(ref count);
    var cloudEvent = await request.ToCloudEventAsync(formatter);
    if (cloudEvent is null)
    {
        logger.LogWarning("Got empty DEADLETTER cloud event.");
        return Results.BadRequest("Got empty DEADLETTER cloud event.");
    }
    if (cloudEvent.Data is null)
    {
        logger.LogWarning("Got empty DEADLETTER data.");
        return Results.BadRequest("Got empty DEADLETTER data.");
    }
    else if (cloudEvent.Data is Message message)
    {
        logger.LogWarning($"{execNumber:000}: Received DEADLETTER message: {message.Value}, id: {cloudEvent.Id}, type: {cloudEvent.Type}, source: {cloudEvent.Source}, subject: {cloudEvent.Subject}, time: {cloudEvent.Time}, spec version: {cloudEvent.SpecVersion.VersionId}, data schema: {cloudEvent.DataSchema?.ToString() ?? "null"}, data content type: {cloudEvent.DataContentType}");
    }
    else
    {
        logger.LogWarning($"Got unexpected DEADLETTER message. Type: {cloudEvent.Data.GetType().FullName}. Details: {cloudEvent.Data}.");
    }
    return Results.Ok();
});

app.Run($"http://0.0.0.0:{app.Configuration.GetValue("PORT", "8080")}");

public partial class Program
{
    static int count = 0;
}

record struct Message(string Value)
{
    private readonly static JsonEventFormatter formatter = new JsonEventFormatter<Message>(new JsonSerializerOptions { TypeInfoResolver = JsonTypeInfoResolver.Combine(MyJsonContext.Default) }, default);
    // required for option 2
    public static async ValueTask<Message?> BindAsync(HttpContext context)
    {
        var cloudEvent = await context.Request.ToCloudEventAsync(formatter);
        return cloudEvent.Data is Message message ? message : null;
    }

}

// this makes it AOT compatible:
[JsonSerializable(typeof(Message))]
internal partial class MyJsonContext : JsonSerializerContext
{
}
