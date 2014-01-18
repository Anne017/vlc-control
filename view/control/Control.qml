import QtQuick 2.0
import Ubuntu.Components 0.1
import "../"

Page {
    id: controls
    property string stPlay: "playing"
    property string stPause: "paused"
    property string stStop: "stopped"
    property var currentItem: playlist.currentItem
    property var currentState: main.currentState
    property bool updateState: false
    property bool checkState: false
    property bool isAudio: false

//    // TODO - TEST ONLY
//    tools: ToolbarItems {
//        locked: true
//        opened: true
//        ToolbarButton {
//            text: i18n.tr("Playlist")
//            iconSource: "../../img/repeat2.png"
//            onTriggered: playlist.toogleExpanded()
//        }
//        ToolbarButton {
//            text: i18n.tr("Shuffle")
//            iconSource: "../../img/shuffle.png"
//            onTriggered: print("shuffle")
//        }
//    }

    onCurrentItemChanged:
    {
        if (currentItem) {
            setState(stPlay);
        }
        timer.updateMaximumValue();
        timer.updateValue(0);
    }

    onCurrentStateChanged:
    {
        if (currentState && (!checkState || currentState.state === state))
        {
            updateState = true;
            setState(currentState.state);

            if (currentState.information && currentState.information.category['Stream 0'].Type === "Audio") {
                isAudio = true;
            } else {
                isAudio = false;
            }

            volume.updateVolume(currentState.volume);
            timer.updateValue(currentState.time);
            info.meta = getMetadata();
            art.meta = getMetadata();
            updateState = false;
            checkState = false;
        }
    }

    VolumeControl {
        id: volume
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: units.gu(2)

        onValueChanged: {
            if (!updateState) {
                main.volume(convertToVLC(value));
            }
        }

    }

    Rectangle {
        id: content
        color: "#222"
        anchors.top: volume.bottom
        anchors.bottom: actions.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: units.gu(2)

        Playlist {
            id: playlist
            view.expanded: isStopped()
            anchors.fill: parent
        }

        CoverArtControl {
            id: art
            visible: !isStopped()

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: playlist.view.height + units.gu(1)
            anchors.bottomMargin: units.gu(1)

            onClick: tooglePlay()

            onMoveUp: volume.forward(volJump)
            onMoveDown: volume.backward(volJump)
            onMoveLeft: timer.backward(timeJump)
            onMoveRight: timer.forward(timeJump)

            onSwipeUp: playlist.prev()
            onSwipeDown: playlist.next()
            onSwipeLeft: playlist.next()
            onSwipeRight: playlist.prev()
        }

        InfoControl {
            id: info
            visible: (!isStopped() && isAudio && art.height > height)
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(2)
        }

    }

    ActionsControl {
        id: actions
        isPlaying: controls.isPlaying();
        anchors.bottom: timer.top
        anchors.horizontalCenter: parent.horizontalCenter

        onClickPlay: play();
        onClickPause: pause();
        onClickStop: stop();
        onClickNext: playlist.next();
        onClickPrev: playlist.prev();
    }

    TimerControl {
        id: timer
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: units.gu(2)

        onValueChanged: {
            if (!updateState) {
                main.seek(Math.floor(value));
            }
        }
    }

    // workaround for updating play/pause buttons quicly
    function setState(stat)
    {        
        state = stat;

        if (isPlaying()) {
            actions.isPlaying = true;
        } else {
            actions.isPlaying = false;
        }
    }

    function play() {
        checkState = true;
        setState(stPlay);
        main.pause(); // toggle play/pause
    }

    function pause() {
        checkState = true;
        setState(stPause);
        main.pause();
    }

    function stop()
    {
        checkState = true;
        timer.updateValue(0);
        setState(stStop);
        main.stop();
    }

    function tooglePlay()
    {
        if (isPlaying()) {
            pause();
        } else {
            play();
        }
    }

    function isPlaying() {
        return (state === stPlay);
    }
    function isPaused() {
        return (state === stPause);
    }
    function isStopped() {
        return (state === stStop);
    }

    function getMetadata()
    {
        var meta = null;

        if (currentState && currentState.information && currentState.information.category) {
            meta = currentState.information.category.meta;
        }
        return meta;
    }
}