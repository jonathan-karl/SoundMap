const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp();

exports.aggregateUploadsData = onDocumentWritten("uploads/{uploadId}", async (event) => {
    const db = getFirestore();
    const WIP = "Noise data processing...";

    try {
        const uploadsRef = db.collection('uploads');
        const outputsRef = db.collection('outputs');

        // Fetch all uploads
        const uploadsSnapshot = await uploadsRef.get();

        let aggregates = {};

        uploadsSnapshot.forEach(doc => {
            const data = doc.data();
            const placeID = data.placeID;

            if (!aggregates[placeID]) {
                aggregates[placeID] = {
                    conversationDifficulty: {}, 
                    noiseSources: {},
                    placeTypes: {},
                    placeName: data.placeName || "Unknown Place",
                    placeAddress: data.placeAddress || "Unknown Address",
                    placeLon: data.placeLon || 0,
                    placeLat: data.placeLat || 0,
                    totalNoiseLevel: 0,
                    noiseLevelCount: 0
                };
            }

            if (data.conversationDifficulty) {
                const difficulty = data.conversationDifficulty;
                aggregates[placeID].conversationDifficulty[difficulty] = 
                    (aggregates[placeID].conversationDifficulty[difficulty] || 0) + 1;
            }

            if (data.currentNoiseLevel !== undefined) {
                aggregates[placeID].totalNoiseLevel += data.currentNoiseLevel;
                aggregates[placeID].noiseLevelCount += 1;
            }

            if (Array.isArray(data.noiseSources)) {
                data.noiseSources.forEach(source => {
                    aggregates[placeID].noiseSources[source] = 
                        (aggregates[placeID].noiseSources[source] || 0) + 1;
                });
            }

            if (data.placeType) {
                const placeType = data.placeType;
                aggregates[placeID].placeTypes[placeType] = 
                    (aggregates[placeID].placeTypes[placeType] || 0) + 1;
            }
        });

        const batch = db.batch();

        for (const placeID in aggregates) {
            const {conversationDifficulty, noiseSources, placeTypes, placeName, placeAddress, placeLon, placeLat, totalNoiseLevel, noiseLevelCount} = aggregates[placeID];
            let conversationDifficultyElements = [], conversationDifficultyFrequencies = [];
            let noiseSourcesElements = [], noiseSourcesFrequencies = [];
            let averageNoiseLevel = noiseLevelCount > 0 ? totalNoiseLevel / noiseLevelCount : 0;

            let placeType = "";
            const placeTypesArray = Object.entries(placeTypes);
            if (placeTypesArray.length > 0) {
                placeTypesArray.sort((a, b) => b[1] - a[1]);
                const highestFrequency = placeTypesArray[0][1];
                const topPlaceTypes = placeTypesArray.filter(([type, freq]) => freq === highestFrequency);
                placeType = topPlaceTypes[Math.floor(Math.random() * topPlaceTypes.length)][0];
            }

            if (Object.keys(conversationDifficulty).length > 0) {
                const sortedDifficulties = Object.entries(conversationDifficulty).sort((a, b) => b[1] - a[1]);
                sortedDifficulties.forEach(([element, frequency]) => {
                    conversationDifficultyElements.push(element);
                    conversationDifficultyFrequencies.push(frequency);
                });
            }

            if (Object.keys(noiseSources).length > 0) {
                const sortedSources = Object.entries(noiseSources).sort((a, b) => b[1] - a[1]);
                sortedSources.forEach(([element, frequency]) => {
                    noiseSourcesElements.push(element);
                    noiseSourcesFrequencies.push(frequency);
                });
            }

            batch.set(outputsRef.doc(placeID), {
                conversationDifficultyElements,
                conversationDifficultyFrequencies,
                noiseSourcesElements,
                noiseSourcesFrequencies,
                placeName,
                placeAddress,
                placeLon,
                placeLat,
                placeID,
                placeType,
                averageNoiseLevel,
                WIP
            }, {merge: true});
        }

        await batch.commit();
    } catch (error) {
        console.error("Error aggregating uploads data:", error);
    }
});