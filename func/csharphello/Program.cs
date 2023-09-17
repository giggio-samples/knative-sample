var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
var target = app.Configuration.GetValue("TARGET", "World!");
app.MapGet("/", () => $"Hello {target}!");
var delay = app.Configuration.GetValue<int>("DelayInMs", 0);
app.MapGet("/delay", (ILogger<Program> logger) =>
{
    if (delay > 0)
    {
        logger.LogInformation($"Sleeping for {delay} ms...");
        Thread.Sleep(delay);
    }
    return $"With delay: {delay}ms.";
});
app.Run($"http://0.0.0.0:{app.Configuration.GetValue("PORT", "8080")}");
