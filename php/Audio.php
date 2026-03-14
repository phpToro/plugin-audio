<?php

namespace PhpToro\Plugins\Audio;

class Audio
{
    public static function play(string $path, array $options = []): mixed
    {
        $args = array_merge($options, ['path' => $path]);
        $json = phptoro_native_call('audio', 'play', json_encode($args));
        return json_decode($json, true);
    }

    public static function pause(): bool
    {
        $json = phptoro_native_call('audio', 'pause', '{}');
        return json_decode($json, true) === true;
    }

    public static function resume(): bool
    {
        $json = phptoro_native_call('audio', 'resume', '{}');
        return json_decode($json, true) === true;
    }

    public static function stop(): bool
    {
        $json = phptoro_native_call('audio', 'stop', '{}');
        return json_decode($json, true) === true;
    }

    public static function setVolume(float $volume): bool
    {
        $json = phptoro_native_call('audio', 'setVolume', json_encode(['volume' => $volume]));
        return json_decode($json, true) === true;
    }

    public static function isPlaying(): bool
    {
        $json = phptoro_native_call('audio', 'isPlaying', '{}');
        return json_decode($json, true) === true;
    }

    public static function startRecording(): array
    {
        $json = phptoro_native_call('audio', 'startRecording', '{}');
        return json_decode($json, true) ?? [];
    }

    public static function stopRecording(): array
    {
        $json = phptoro_native_call('audio', 'stopRecording', '{}');
        return json_decode($json, true) ?? [];
    }
}
