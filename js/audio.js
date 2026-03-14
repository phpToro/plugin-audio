phpToro.audio = {
    play: function(path, options) {
        return phpToro.nativeCall('audio', 'play', Object.assign({ path: path }, options || {}));
    },
    pause: function() {
        return phpToro.nativeCall('audio', 'pause', {});
    },
    resume: function() {
        return phpToro.nativeCall('audio', 'resume', {});
    },
    stop: function() {
        return phpToro.nativeCall('audio', 'stop', {});
    },
    setVolume: function(volume) {
        return phpToro.nativeCall('audio', 'setVolume', { volume: volume });
    },
    isPlaying: function() {
        return phpToro.nativeCall('audio', 'isPlaying', {});
    },
    startRecording: function() {
        return phpToro.nativeCall('audio', 'startRecording', {});
    },
    stopRecording: function() {
        return phpToro.nativeCall('audio', 'stopRecording', {});
    }
};
