using DocoptNet;

[DocoptArguments]
partial class ProgramArguments
{
  const string Help = @"Producer.

    Usage:
      producer (--url=URL | [--ip=IP] [--namespace=NAMESPACE] [--broker=BROKER]) [--type=TYPE] [--host=HOST] [--subject=SUBJECT] [--exit | (--no-interactive [--parallel=PARALLEL] [--delay=DELAY])]
      producer (-h | --help)
      producer --version

    Options:
      --exit                    Exit after sending one request.
      --no-interactive          Will run without interaction, producing values using the parallelism defined by --parallel. If terminal is not interactive (i.e. running in a script) this is the default.
      --parallel=PARALLEL       Send multiple requests in parallel [default: 2].
      --delay=DELAY             Delay between requests in milliseconds [default: 500].
      --type=TYPE               Event Type [default: producer1].
      --subject=SUBJECT         Event Subject [default: test].
      --url=URL                 Broker URL.
      --ip=IP                   Broker IP [default: http://172.21.1.0].
      --namespace=NAMESPACE     Broker kubernetes namespace [default: consumerns].
      --broker=BROKER           Broker name [default: my-broker].
      --host=HOST               Broker host header.
      -h --help                 Show this screen.
      --version                 Show version.
";
  public static string Version => $"producer {typeof(ProgramArguments).Assembly.GetName().Version}";
  public static IParser<ProgramArguments> CreateParserWithVersion() => CreateParser().WithVersion(Version);
}
