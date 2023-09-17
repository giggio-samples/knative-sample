using System.Net.Mime;
using CloudNative.CloudEvents;
using CloudNative.CloudEvents.Http;
using CloudNative.CloudEvents.SystemTextJson;
using static System.Console;

ProgramArguments programArguments = new();
var result = ProgramArguments.CreateParserWithVersion()
.Parse(args)
.Match(p => { programArguments = p; return -1; },
    result => { WriteLine(result.Help); return 0; },
    result => { WriteLine(result.Version); return 0; },
    result => { Error.WriteLine(result.Usage); return 1; });
if (result > -1) return result;

CancellationTokenSource cancellationTokenSource = new();
void ExitHandler()
{
    WriteLine("Done.");
    cancellationTokenSource.Cancel();
}
AppDomain.CurrentDomain.ProcessExit += (sender, args) => ExitHandler();
Console.CancelKeyPress += (sender, args) => ExitHandler();
Console.TreatControlCAsInput = false;

using var http = new HttpClient();
var formatter = new JsonEventFormatter();
var url = programArguments.OptUrl;
Uri brokerUrl;
if (url is null)
{
    // example: "http://broker-ingress.knative-eventing.svc.cluster.local/default/in-memory-broker";
    brokerUrl = new Uri($"http://{programArguments.OptIp}/{programArguments.OptNamespace}/{programArguments.OptBroker}");
}
else
{
    // example: "http://broker-ingress.knativetest.localhost"
    if (!url.StartsWith("http://")) url = $"http://{url}";
    brokerUrl = new Uri(url);
}
var isInteractive = !programArguments.OptNoInteractive && Environment.UserInteractive;
var maxDegreeOfParallelism = (!isInteractive && int.TryParse(programArguments.OptParallel, out var parallelArg) && parallelArg > 1) ? parallelArg : 1;
var delay = (!isInteractive && int.TryParse(programArguments.OptDelay, out var delayArg) && delayArg > 0) ? delayArg : 0;
WriteLine($"\nStarting...\nBroker url: {brokerUrl}\nType: {programArguments.OptType}\nSubject: {programArguments.OptSubject}\nParallel: {maxDegreeOfParallelism}\nIs interactive: {isInteractive}\nDelay: {delay}\nExit:{programArguments.OptExit}\n");
if (!isInteractive)
    WriteLine("Press CTRL+C to exit.");
await Parallel.ForEachAsync(GetNextValue(cancellationTokenSource.Token, isInteractive: isInteractive, exit: programArguments.OptExit),
    new ParallelOptions { MaxDegreeOfParallelism = maxDegreeOfParallelism },
    async (fullMessage, _) =>
{
    WriteLine($"Sending: '{fullMessage}'...");
    var message = new Message(fullMessage);
    var cloudEvent = new CloudEvent
    {
        Id = Guid.NewGuid().ToString(),
        Type = programArguments.OptType,
        Source = new Uri("https://giggio.net/"),
        Time = DateTimeOffset.UtcNow,
        DataContentType = MediaTypeNames.Application.Json,
        Subject = programArguments.OptSubject,
        Data = message
    };
    if (!isInteractive && delay > 0)
        await Task.Delay(delay, cancellationTokenSource.Token);
    var response = await http.SendAsync(new(HttpMethod.Post, brokerUrl)
    {
        Headers = { Host = programArguments.OptHost },
        Content = cloudEvent.ToHttpContent(ContentMode.Binary, formatter)
    }, cancellationTokenSource.Token);
    var log = $"Message sent, id: {cloudEvent.Id}, Status: {(int)response.StatusCode} ({response.StatusCode})\n";
    var content = await response.Content.ReadAsStringAsync(cancellationTokenSource.Token);
    if (response.IsSuccessStatusCode)
        WriteLine(log);
    else
        WriteLineRed(log);
    if (!string.IsNullOrWhiteSpace(content))
        WriteLine($"Content: {content}");
});
return 0;

static void WriteLineRed(string message)
{
    var color = ForegroundColor;
    ForegroundColor = ConsoleColor.Red;
    WriteLine(message);
    ForegroundColor = color;
}

static IEnumerable<string> GetNextValue(CancellationToken cancellationToken, bool isInteractive, bool exit)
{
    yield return $"Test {DateTime.Now}";
    if (exit) yield break;
    if (isInteractive)
    {
        var count = 0;
        do
        {
            WriteLine("\nWrite a message! Type <enter> to exit.");
            var input = ReadLine();
            if (cancellationToken.IsCancellationRequested)
                break;
            else if (string.IsNullOrWhiteSpace(input))
                break;
            else
                yield return $"{++count:0,000}: {input}";
        } while (true);
    }
    else
    {
        var count = 0;
        while (!cancellationToken.IsCancellationRequested)
        {
            var now = DateTime.Now;
            yield return $"{++count:000000000,000}: Test {now}:{now.Millisecond}";
        }
    }
}

record struct Message(string Value);