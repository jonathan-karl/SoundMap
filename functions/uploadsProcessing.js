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
                        conversationDifficulty: {
                            morning: {},
                            afternoon: {},
                            evening: {},
                            overall: {} // Added overall conversation difficulty
                        },
                        noiseSources: {},
                        placeTypes: {},
                        placeName: data.placeName || "Unknown Place",
                        placeAddress: data.placeAddress || "Unknown Address",
                        placeLon: data.placeLon || 0,
                        placeLat: data.placeLat || 0,
                        noiseLevel: {
                            morning: { total: 0, count: 0 },
                            afternoon: { total: 0, count: 0 },
                            evening: { total: 0, count: 0 },
                            overall: { total: 0, count: 0 }
                        },
                        submissionCount: 0,
                        latestUploadTimestamp: null
                    };
                }

                // Update latest upload timestamp if this upload is newer
                if (!aggregates[placeID].latestUploadTimestamp || 
                    data.uploadTime > aggregates[placeID].latestUploadTimestamp) {
                    aggregates[placeID].latestUploadTimestamp = data.uploadTime;
                }

                // Increment submission count for this placeID
                aggregates[placeID].submissionCount++;

                // Determine time of day based on upload timestamp
                const uploadTime = data.uploadTime?.toDate() || new Date();
                const hour = uploadTime.getHours();
                let timeOfDay;

                if (hour >= 6 && hour < 12) {
                    timeOfDay = 'morning';
                } else if (hour >= 12 && hour < 18) {
                    timeOfDay = 'afternoon';
                } else {
                    timeOfDay = 'evening';
                }

                // Aggregate conversationDifficulty by time of day and overall
                if (data.hasOwnProperty('conversationDifficulty')) {
                    const difficulty = data.conversationDifficulty;
                    // Time-based aggregation
                    aggregates[placeID].conversationDifficulty[timeOfDay][difficulty] = 
                        (aggregates[placeID].conversationDifficulty[timeOfDay][difficulty] || 0) + 1;
                    // Overall aggregation
                    aggregates[placeID].conversationDifficulty.overall[difficulty] = 
                        (aggregates[placeID].conversationDifficulty.overall[difficulty] || 0) + 1;
                }
                
                // Aggregate currentNoiseLevel for both time of day and overall
                if (data.hasOwnProperty('currentNoiseLevel')) {
                    // Time-based noise level
                    aggregates[placeID].noiseLevel[timeOfDay].total += data.currentNoiseLevel;
                    aggregates[placeID].noiseLevel[timeOfDay].count += 1;
                    // Overall noise level
                    aggregates[placeID].noiseLevel.overall.total += data.currentNoiseLevel;
                    aggregates[placeID].noiseLevel.overall.count += 1;
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
                const {
                    conversationDifficulty,
                    noiseSources,
                    placeTypes,
                    placeName,
                    placeAddress,
                    placeLon,
                    placeLat,
                    noiseLevel,
                    submissionCount,
                    latestUploadTimestamp
                } = aggregates[placeID];

                // Process conversation difficulties (overall)
                let conversationDifficultyElements = [], conversationDifficultyFrequencies = [];
                if (Object.keys(conversationDifficulty.overall).length > 0) {
                    const sortedDifficulties = Object.entries(conversationDifficulty.overall)
                        .sort((a, b) => b[1] - a[1]);
                    sortedDifficulties.forEach(([element, frequency]) => {
                        conversationDifficultyElements.push(element);
                        conversationDifficultyFrequencies.push(frequency);
                    });
                }

                // Process time-based conversation difficulties
                const timeBasedDifficulties = {};
                for (const period of ['morning', 'afternoon', 'evening']) {
                    const periodData = conversationDifficulty[period];
                    let maxCount = 0;
                    let majorityDifficulty = 'Unknown';
                    
                    for (const [difficulty, count] of Object.entries(periodData)) {
                        if (count > maxCount) {
                            maxCount = count;
                            majorityDifficulty = difficulty;
                        }
                    }
                    timeBasedDifficulties[period] = majorityDifficulty;
                }

                // Process time-based noise levels
                const timeBasedNoiseLevels = {};
                for (const period of ['morning', 'afternoon', 'evening']) {
                    const periodData = noiseLevel[period];
                    timeBasedNoiseLevels[period] = periodData.count > 0 
                        ? periodData.total / periodData.count 
                        : 0;
                }

                // Calculate overall average noise level
                const averageNoiseLevel = noiseLevel.overall.count > 0 
                    ? noiseLevel.overall.total / noiseLevel.overall.count 
                    : 0;

                // Process noise sources
                let noiseSourcesElements = [], noiseSourcesFrequencies = [];
                if (Object.keys(noiseSources).length > 0) {
                    const sortedSources = Object.entries(noiseSources).sort((a, b) => b[1] - a[1]);
                    sortedSources.forEach(([element, frequency]) => {
                        noiseSourcesElements.push(element);
                        const percentage = Math.round((frequency / submissionCount) * 100);
                        noiseSourcesFrequencies.push(percentage);
                    });
                }

                // Determine majority place type
                let placeType = "";
                const placeTypesArray = Object.entries(placeTypes);
                if (placeTypesArray.length > 0) {
                    placeTypesArray.sort((a, b) => b[1] - a[1]);
                    const highestFrequency = placeTypesArray[0][1];
                    const topPlaceTypes = placeTypesArray.filter(([type, freq]) => freq === highestFrequency);
                    placeType = topPlaceTypes[Math.floor(Math.random() * topPlaceTypes.length)][0];
                }

                // Update or create the document in outputs collection
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
                    placeType,
                    averageNoiseLevel,
                    timeBasedData: {
                        morning: {
                            conversationDifficulty: timeBasedDifficulties.morning,
                            averageNoiseLevel: timeBasedNoiseLevels.morning
                        },
                        afternoon: {
                            conversationDifficulty: timeBasedDifficulties.afternoon,
                            averageNoiseLevel: timeBasedNoiseLevels.afternoon
                        },
                        evening: {
                            conversationDifficulty: timeBasedDifficulties.evening,
                            averageNoiseLevel: timeBasedNoiseLevels.evening
                        }
                    },
                    submissionCount,
                    latestUploadTimestamp,
                    WIP: WIP
                }, {merge: true});
            }
        } catch (error) {
            console.error("Error aggregating uploads data:", error);
        }
    });