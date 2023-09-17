using System.Text.Json;
using System.Text.Json.Serialization.Metadata;
using CloudNative.CloudEvents;
using CloudNative.CloudEvents.AspNetCore;
using CloudNative.CloudEvents.SystemTextJson;

namespace consumer;

public class Event
{
    private readonly static JsonEventFormatter formatter = new JsonEventFormatter<Message>(new JsonSerializerOptions { TypeInfoResolver = JsonTypeInfoResolver.Combine(MyJsonContext.Default) }, default);
    public static async ValueTask<Event?> BindAsync(HttpContext context)
    {
        var cloudEvent = await context.Request.ToCloudEventAsync(formatter);
        return new Event { CloudEvent = cloudEvent };
    }
    public required CloudEvent CloudEvent { get; init; }
}
