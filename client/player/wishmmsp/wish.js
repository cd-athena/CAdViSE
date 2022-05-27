var WISHRule;

var MIN_BUFFER_RATIO = 0.2;
var alpha = 0;
var beta = 0;
var gamma = 0;
var denominator_exp = 0;

var smoothThroughputKbps = 0;
var num_downloaded_segments = 0;
var selected_quality_index_array = [];

var last_selected_quality = 0;
var next_selected_quality = 0;
var bitrates = [];
var SD = 0;
var currentbufferS = 0;
var buffer_size = 0;

var low_buff_thresS = 0;


// Define the WISHRule class
function WISHRuleClass() {

    //Some models and controllers provided by Dash.js to gather metrics and return SwitchRequests
    let factory = dashjs.FactoryMaker;
    let SwitchRequest = factory.getClassFactoryByName('SwitchRequest');
    let DashMetrics = factory.getSingletonFactoryByName('DashMetrics');
    let MetricsModel = factory.getSingletonFactoryByName('MetricsModel');
    let StreamController = factory.getSingletonFactoryByName('StreamController');
    let DashManifestModel = factory.getSingletonFactoryByName('DashManifestModel');
    let MediaPlayerModel = factory.getSingletonFactoryByName('MediaPlayerModel');
    let context = this.context;
    let index = 0;
    let instance;

    let qualityLevelList;

    function setup() {
        //A necessary function
        resetInitalSettings();
    }

    function getMaxIndex(rulesContext) {

        if (!rulesContext || !rulesContext.hasOwnProperty('getMediaInfo') || !rulesContext.hasOwnProperty('getMediaType') || !rulesContext.hasOwnProperty('useBufferOccupancyABR') ||
          !rulesContext.hasOwnProperty('getAbrController') || !rulesContext.hasOwnProperty('getScheduleController')) {
            console.log("===== Just return 1 ===");

            return switchRequest;
        }

        // here you can get some informations aboit metrics for example, to implement the rule
        const metricsModel = MetricsModel(context).getInstance();
        const mediaInfo = rulesContext.getMediaInfo();
        const mediaType = rulesContext.getMediaInfo().type; //Fragment type
        const switchRequest = SwitchRequest(context).create();  // switcheRequest.quality = -1 ==> no change
        const scheduleController = rulesContext.getScheduleController();
        scheduleController.setTimeToLoadDelay(0);
        switchRequest.reason = switchRequest.reason || {};

        if(mediaType == 'video'){

            bitrates = mediaInfo.bitrateList.map(b => b.bandwidth/1000);
            const length = bitrates.length;

            const isDynamic = false;
            const metrics = metricsModel.getMetricsFor(mediaType, isDynamic); //General info
            const dashMetrics = DashMetrics(context).getInstance(); //More info
            const streamController = StreamController(context).getInstance();
            const dashManifest = DashManifestModel(context).getInstance();
            const mediaPlayerModel = MediaPlayerModel(context).getInstance();
            const abr = rulesContext.getAbrController();
            const currentBufferState = dashMetrics.getCurrentBufferState(mediaType);
            const useBufferOccupancyABR = rulesContext.useBufferOccupancyABR();

            var httpList = metrics.HttpList;
            if (httpList.length == 0) {
                switchRequest.quality = 0;
                return switchRequest;
            }
            SD = httpList[httpList.length-1]._mediaduration;
            low_buff_thresS = SD;

            num_downloaded_segments = httpList.length;
            console.log('\t ############# num_downloaded_segments: ' + num_downloaded_segments);
            selected_quality_index_array = [];

            for (let i = 0; i < num_downloaded_segments; i ++) {
                selected_quality_index_array.push(httpList[i]._quality);
            }


            const throughputHistory = abr.getThroughputHistory();
            const lastThroughputKbps = throughputHistory.getAverageThroughput(mediaType, true); // In kbits/s

            let lowest_cost = Number.MAX_SAFE_INTEGER;
            let max_quality = 0;

            currentbufferS = dashMetrics.getCurrentBufferLevel('video', isDynamic);
            console.log("lastThroughputKbps: " + lastThroughputKbps + ". Buffer: " + currentbufferS);
            switchRequest.reason.throughput = lastThroughputKbps;
            switchRequest.reason.latency = 0;

            if (last_selected_quality != abr.getQualityFor(mediaType, streamController.getActiveStreamInfo().id)) {
                console.log("===== Expected last quality != actual last quality");
                console.log("\t expected: " + last_selected_quality);
                console.log("\t last    : " + abr.getQualityFor(mediaType, streamController.getActiveStreamInfo().id));
                last_selected_quality = abr.getQualityFor(mediaType, streamController.getActiveStreamInfo().id);

                return switchRequest;
            }

            smoothThroughputKbps = getSmoothThroughput(0.125, lastThroughputKbps, smoothThroughputKbps);
            var estimated_throghputKbps = Math.min(smoothThroughputKbps, lastThroughputKbps);


            qualityLevelList = getQualityFunction(bitrates);
            const m_xi = 0.8;
            const m_delta = 1;
            buffer_size = mediaPlayerModel.getStableBufferTime();
            // buffer_size = 30; // = bufferTimeAtTopQuality
            console.log("------------------- buffer_size: " + buffer_size);
            setWeights(m_xi, m_delta, qualityLevelList, SD);

            if (currentbufferS <= low_buff_thresS) {
                next_selected_quality = 0;
            }
            else {
                for (let i = length-1; i >= 0; i--){
                    if (bitrates[i] < lastThroughputKbps * (1+0.1)) {
                        console.log ("Max considered quality: " + i + ": " + bitrates[i]);
                        max_quality = i;
                        break;
                    }
                }

                if (max_quality === 0) {
                    next_selected_quality = max_quality;
                }

                console.log ("Downloaded segment " + (num_downloaded_segments-1) +
                  " at quality: " + selected_quality_index_array[num_downloaded_segments-1]);

                for (let i = 1; i <= max_quality; i++) {
                    let currentTotalCost = Math.round(100*getTotalCost_v3(rulesContext, bitrates, i, estimated_throghputKbps, currentbufferS, num_downloaded_segments));
                    if (currentTotalCost <= lowest_cost) {
                        next_selected_quality = i;
                        lowest_cost = currentTotalCost;
                        console.log("\t lowest cost: " + next_selected_quality + ": " + lowest_cost);
                    }
                }

            }
            console.log("\t\t selected_quality_index_array.length = " + selected_quality_index_array.length);

            // If the bitrate is not changed
            if (next_selected_quality === last_selected_quality) {
                console.log("\t\t Quality is NOT changed: " + next_selected_quality);
                return switchRequest;
            }
            else {
                console.log("\t\t Quality changes to : " + next_selected_quality);
                last_selected_quality = next_selected_quality;
            }


            switchRequest.quality = next_selected_quality;
            console.log("************* the finall quality = " + switchRequest.quality);
            switchRequest.reason = 'WISH updates';
            switchRequest.priority = SwitchRequest.PRIORITY.STRONG;
            return switchRequest;
        }else{
            console.log("=========== NOT VIDEO TYPE ===========");
            // bitrates = mediaInfo.bitrateList.map(b => b.bandwidth/1000);

            // switchRequest.quality = bitrates.length - 1;
            // const scheduleController = rulesContext.getScheduleController();
            // scheduleController.setTimeToLoadDelay(0);
            // console.log("************* AUDIO quality = " + switchRequest.quality);
            // switchRequest.reason = 'Audio downloads';
            return switchRequest;
        }

    }


    function getQualityFunction(bitrates) {
        // console.log ("\t\t getQualityFunction triggered");
        let qualityLevelList = [];
        let length = bitrates.length;

        for (let i = 0; i < length; i ++) {
            qualityLevelList.push(1.0*bitrates[i]/bitrates[length-1]);
        }

        return qualityLevelList;
    }

    function getSmoothThroughput(margin, lastThroughputKbps, smoothThroughputKbps) {
        // console.log("\t\t getSmoothThroughput triggered");
        if (lastThroughputKbps > 0) {
            if (smoothThroughputKbps === 0) {
                smoothThroughputKbps = lastThroughputKbps;
            }
            else {
                smoothThroughputKbps = (1 - margin) * smoothThroughputKbps + margin * lastThroughputKbps;
            }
        }
        else {
            smoothThroughputKbps = 5000;    // finetune
        }

        return smoothThroughputKbps;
    }

    function setWeights(m_xi, m_delta, qualityLevelList, segment_duration) {
        console.log("==== setWeights triggered === ");
        let R_max_Kbps = bitrates[bitrates.length-1];    // max bitrate

        let R_o_Kbps = bitrates[bitrates.length-1];
        let thrp_optimal = m_delta * R_max_Kbps;
        let last_quality_1_Kbps = bitrates[bitrates.length-2]; // second highest bitrate
        let optimal_delta_buffer_S = buffer_size*m_xi - segment_duration; // bufferMax*(m_xi - MIN_BUFFER_RATIO)

        let temp_beta_alpha = optimal_delta_buffer_S/segment_duration;
        let temp_a = 2.0*Math.exp(1 + last_quality_1_Kbps/R_max_Kbps - 2.0*R_o_Kbps/R_max_Kbps);
        let temp_b = (1 + temp_beta_alpha*segment_duration/(optimal_delta_buffer_S))/thrp_optimal;

        denominator_exp = Math.exp(2*qualityLevelList[qualityLevelList.length-1] - 2*qualityLevelList[0]);
        alpha = 1.0/(1 + temp_beta_alpha + R_max_Kbps*temp_b*denominator_exp/temp_a);
        beta = temp_beta_alpha*alpha;
        gamma = 1 - alpha - beta;
        console.log("\t alpha: " + alpha + "\n\tbeta: " + beta + "\n\tgamma: " + gamma);
    }

    function getTotalCost_v3(rulesContext, bitrates, qualityIndex,
      estimated_throghputKbps, currentbufferS, num_downloaded_segments) {
        // console.log("\t getTotalCost_v3 triggered ");
        // console.log("\t qualityIndex: " + qualityIndex);
        let totalCost;
        let bandwidthCost;
        let bufferCost;
        let qualityCost;
        let current_quality_level = qualityLevelList[qualityIndex];

        let temp = bitrates[qualityIndex]*1.0/estimated_throghputKbps;  // bitrate is in bps
        let average_quality = 0;
        let slice_window = 10;
        let length_quality = qualityLevelList.length;
        let quality_window = Math.min(slice_window, num_downloaded_segments);
        // console.log("\t quality_window: " + quality_window);

        for (let i = 1; i <= quality_window; i++){
            let m_qualityIndex = selected_quality_index_array[num_downloaded_segments-i];
            average_quality += qualityLevelList[m_qualityIndex];
        }

        average_quality = average_quality*1.0/quality_window;

        bandwidthCost = temp;

        // console.log("\t qualityLevelList: " + qualityLevelList[qualityIndex]);
        // console.log("\t average_quality: " + average_quality);
        // console.log("\t current_quality_level: " + current_quality_level);

        console.log("\t currentbufferS: " + currentbufferS + "\t low_buff_thresS: " + low_buff_thresS);
        bufferCost = temp*(SD*1.0/(currentbufferS - low_buff_thresS));
        qualityCost = Math.exp(qualityLevelList[length_quality-1] + average_quality - 2*current_quality_level)/denominator_exp;
        totalCost = alpha*bandwidthCost + beta*bufferCost + gamma*qualityCost;


        // console.log("\n Cost of quality " + (qualityIndex) + "\t bitrate: " + bitrates[qualityIndex] + "\t thrp: " + estimated_throghputKbps +
        //     "\n\t==> bandwidthCost: " + bandwidthCost +
        //     "\n\t==> bufferCost: " + bufferCost + "\n\t==> qualityCost: " + qualityCost);
        console.log("=======> Total cost of " + (qualityIndex) + ": " + totalCost);

        return totalCost;
    }


    function resetInitalSettings() {
        console.log("------------------ Reset Everything --------------");
        smoothThroughputKbps = 0;
        num_downloaded_segments = 0;
        selected_quality_index_array = [];

        last_selected_quality = 0;
        next_selected_quality = 0;
    }

    function reset() {
        // resetInitalSettings();
    }


    instance = {
        getMaxIndex: getMaxIndex,
        reset: reset
    };

    setup();

    return instance;
}

//These two are necessary as will be seen in main.js where the ABR rule switching happens

WISHRuleClass.__dashjs_factory_name = 'WISHRule';
WISHRule = dashjs.FactoryMaker.getClassFactory(WISHRuleClass);