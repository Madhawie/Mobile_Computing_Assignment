namespace LittleBloom.Api.Metrics;

/// <summary>
/// Wraps the response body and counts the bytes written through it, so the server can log how
/// big each sync response was (compare with the phone's byte count and with Wireshark).
/// Write-only: everything is passed straight on to the real body.
/// </summary>
public sealed class CountingStream : Stream
{
    private readonly Stream _inner;

    public CountingStream(Stream inner) => _inner = inner;

    public long BytesWritten { get; private set; }

    public override bool CanRead => false;
    public override bool CanSeek => false;
    public override bool CanWrite => true;
    public override long Length => throw new NotSupportedException();

    public override long Position
    {
        get => throw new NotSupportedException();
        set => throw new NotSupportedException();
    }

    public override void Write(byte[] buffer, int offset, int count)
    {
        BytesWritten += count;
        _inner.Write(buffer, offset, count);
    }

    public override void Write(ReadOnlySpan<byte> buffer)
    {
        BytesWritten += buffer.Length;
        _inner.Write(buffer);
    }

    public override Task WriteAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
    {
        BytesWritten += count;
        return _inner.WriteAsync(buffer, offset, count, cancellationToken);
    }

    public override ValueTask WriteAsync(ReadOnlyMemory<byte> buffer, CancellationToken cancellationToken = default)
    {
        BytesWritten += buffer.Length;
        return _inner.WriteAsync(buffer, cancellationToken);
    }

    public override void Flush() => _inner.Flush();

    public override Task FlushAsync(CancellationToken cancellationToken) => _inner.FlushAsync(cancellationToken);

    public override int Read(byte[] buffer, int offset, int count) => throw new NotSupportedException();
    public override long Seek(long offset, SeekOrigin origin) => throw new NotSupportedException();
    public override void SetLength(long value) => throw new NotSupportedException();
}
