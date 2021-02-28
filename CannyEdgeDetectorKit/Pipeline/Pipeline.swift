//
//  Pipeline.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 20/02/2021.
//

import Foundation

class Pipeline{
    var steps: [PipelineStep]
    var outputs: [PipelineData]?{
        steps.last?.outputs
    }
    
    init(){
        self.steps = []
    }
    
    func addStep(step: PipelineStep) -> Pipeline{
        self.steps.append(step)
        return self
    }
    
    func execute(input: PipelineData) throws{
        try self.execute(inputs: [input])
    }
    
    func execute(inputs: [PipelineData]) throws{
        var tempInputs = inputs
        for step in steps{
            step.addInputs(data: tempInputs)
            try step.execute()
            tempInputs = step.outputs
        }
    }
}
