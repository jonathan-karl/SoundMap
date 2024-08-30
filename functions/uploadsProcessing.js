const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.aggregateUploadsData = functions.firestore
    .document('uploads/{uploadId}')
    .onWrite(async (change, context) => {
        
        const WIP = "Noise data processing...";

        try {
            const uploadsRef = admin.firestore().collection('uploads');
            const outputsRef = admin.firestore().collection('outputs');

            // Fetch all uploads
            const uploadsSnapshot = await uploadsRef.get();

            let aggregates = {};

            uploadsSnapshot.forEach(doc => {
                const data = doc.data();
                const placeID = data.placeID;

                // Initialize a new entry for this placeID if it doesn't already exist
                if (!aggregates[placeID]) {
                    aggregates[placeID] = {
                        conversationDifficulty: {}, 
                        noiseSources: {},
                        placeTypes: {},  // Add a dictionary for placeTypes aggregation
                        placeName: data.placeName || "Unknown Place",
                        placeAddress: data.placeAddress || "Unknown Address",
                        placeLon: data.placeLon || 0,
                        placeLat: data.placeLat || 0,
                        totalNoiseLevel: 0, 
                        noiseLevelCount: 0
                    };
                }

                // Aggregate conversationDifficulty as before
                if (data.hasOwnProperty('conversationDifficulty')) {
                    const difficulty = data.conversationDifficulty;
                    aggregates[placeID].conversationDifficulty[difficulty] = 
                        (aggregates[placeID].conversationDifficulty[difficulty] || 0) + 1;
                }
                
                // Aggregate currentNoiseLevel
                if (data.hasOwnProperty('currentNoiseLevel')) {
                    aggregates[placeID].totalNoiseLevel += data.currentNoiseLevel;
                    aggregates[placeID].noiseLevelCount += 1;
                }

                // Aggregate noiseSources
                if (Array.isArray(data.noiseSources)) {
                    data.noiseSources.forEach(source => {
                        aggregates[placeID].noiseSources[source] = 
                            (aggregates[placeID].noiseSources[source] || 0) + 1;
                    });
                }

                // Aggregate placeType
                if (data.hasOwnProperty('placeType')) {
                    const placeType = data.placeType;
                    aggregates[placeID].placeTypes[placeType] = 
                        (aggregates[placeID].placeTypes[placeType] || 0) + 1;
                }
            });

            for (const placeID in aggregates) {
              const {conversationDifficulty, noiseSources, placeTypes, placeName, placeAddress, placeLon, placeLat, totalNoiseLevel, noiseLevelCount} = aggregates[placeID];
              let conversationDifficultyElements = [], conversationDifficultyFrequencies = [];
              let noiseSourcesElements = [], noiseSourcesFrequencies = [];
              let averageNoiseLevel = noiseLevelCount > 0 ? totalNoiseLevel / noiseLevelCount : 0;

              // Determine the majority placeType
              let placeType = "";
              const placeTypesArray = Object.entries(placeTypes);
              if (placeTypesArray.length > 0) {
                  placeTypesArray.sort((a, b) => b[1] - a[1]);  // Sort by frequency descending
                  const highestFrequency = placeTypesArray[0][1];
                  
                  // Filter to get all types with the highest frequency
                  const topPlaceTypes = placeTypesArray.filter(([type, freq]) => freq === highestFrequency);
                  
                  // Randomly pick one if there's a tie
                  placeType = topPlaceTypes[Math.floor(Math.random() * topPlaceTypes.length)][0];
              }

                // Generate arrays for conversationDifficulty and noiseSources elements and frequencies
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

                // Update or create the document in outputs collection with the additional fields
                await outputsRef.doc(placeID).set({
                    conversationDifficultyElements,
                    conversationDifficultyFrequencies,
                    noiseSourcesElements,
                    noiseSourcesFrequencies,
                    placeName,
                    placeAddress,
                    placeLon,
                    placeLat,
                    placeID,
                    placeType,  // Add the determined placeType
                    averageNoiseLevel, // Add the average noise level
                    WIP: WIP  // Include the WIP status
                }, {merge: true});
            }
        } catch (error) {
            console.error("Error aggregating uploads data:", error);
        }
    });
