import QtQuick 2.0
import QtQuick.Window 2.0
import QtLocation 5.6
import QtPositioning 5.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Window {
    width: 512
    height: 512
    visible: true
    property variant currentLocation: QtPositioning.coordinate(37.368832, -122.036346)
    property string searchString: "Thai food"
    property bool isPopupOpen: false
    property string destinationString: "Sunnyvale"

    onDestinationStringChanged: {
        console.log("onDestinationStringChanged")
//        geocodeModel.query = destinationString
    }


    Plugin {
        id: mapPlugin
        name: "osm"
    }

    GeocodeModel {
        id: geocodeModel
        plugin: mapPlugin
        autoUpdate: false
        query: destinationString + ", United States"
        Component.onCompleted: geocodeModel.update()
        onQueryChanged: {
            console.log("onQueryChanged")
//            geocodeModel.update()
        }
        onLocationsChanged: {
            var coord = geocodeModel.get(0).coordinate
            searchModel.searchArea = QtPositioning.circle(coord)
            map.center = coord
            console.log(coord)
            searchModel.update()
        }
    }

    PositionSource {
        id: src
        updateInterval: 1000
        active: true
        preferredPositioningMethods: PositionSource.AllPositioningMethods
        property variant lastSearchPosition: currentLocation

        onPositionChanged: {
            var coord = src.position.coordinate;
            console.log("Coordinate:", coord.longitude, coord.latitude);
            //            currentLocation = coord

            var currentPosition = src.position.coordinate
            map.center = currentPosition
            var distance = currentPosition.distanceTo(lastSearchPosition)
            if (distance > 500) {
                // 500m from last performed pizza search
                lastSearchPosition = currentPosition
                searchModel.searchArea = QtPositioning.circle(currentPosition)
                searchModel.update()
            }
        }
    }
    PlaceSearchModel {
        id: searchModel
        plugin: mapPlugin
        searchTerm: searchString
        searchArea: QtPositioning.circle(currentLocation.coordinate)
//        searchArea: QtPositioning.circle(geocodeModel.get(0).coordinate)
        Component.onCompleted: update()
    }

    Map {
        id: map
        anchors.fill: parent
        plugin: mapPlugin
        center: currentLocation
        zoomLevel: 12
        gesture.enabled: true
        gesture.acceptedGestures: MapGestureArea.PinchGesture | MapGestureArea.PanGesture | MapGestureArea.FlickGesture

        MapItemView {
            model: searchModel
            delegate: MapQuickItem {
                coordinate: place.location.coordinate

                anchorPoint.x: image.width * 0.00001
                anchorPoint.y: image.height * 0.00001

                sourceItem: Column {
                    Image { id: image; source: "marker.png" }
                    Text { text: title; font.bold: true }
                }
            }
        }

        MouseArea{
            id: mapMouseArea
            anchors.fill: parent
            onDoubleClicked: {
                console.log("Map double clicked")
                if(!isPopupOpen){
                    popup.open()
                    isPopupOpen = true
                }
                else {
                    isPopupOpen = false
                    popup.close()
                }
            }
        }
    }

    Popup {
        id: popup
        parent: map
        width: 300//(parent.width) / 2
        height: 150//(parent.height) / 2
        closePolicy: Popup.OnEscape | Popup.OnPressOutside
        x: 50
        y: 100
        ColumnLayout {
            anchors.fill: parent
            spacing: 2
            TextField {
                id: destrinationStr
                Layout.alignment: Qt.AlignLeft
                placeholderText: qsTr("Enter Destination")
            }
            TextField {
                id: searchStr
                Layout.alignment: Qt.AlignLeft
                placeholderText: qsTr("Enter places to search")
            }
            Button{
                id: searchButton
                Layout.alignment: Qt.AlignLeft
                text: "Search"
                onClicked: {
                    searchString = searchStr.text
                    destinationString = destrinationStr.text
                    geocodeModel.query = destinationString + ", United States"
                    geocodeModel.update()
                    var coord = geocodeModel.get(0).coordinate
                    searchModel.searchArea = QtPositioning.circle(coord)
                    map.center = coord
                    console.log(coord)
                    searchModel.update()
                    console.log(searchString, destrinationStr.text)
                    destrinationStr.text = " "
                    searchStr.text = " "
                    destrinationStr.placeholderText = qsTr("Enter Destination")
                    searchStr.placeholderText = qsTr("Enter places to search")
                    popup.close()

                }
            }
        }
        onClosed: {
            isPopupOpen = false
        }

    }

    Connections {
        target: searchModel
        onStatusChanged: {
            if (searchModel.status == PlaceSearchModel.Error)
                console.log(searchModel.errorString());
        }
    }
}
