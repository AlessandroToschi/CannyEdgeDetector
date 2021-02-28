//
//  PipelineStep.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 20/02/2021.
//

import Foundation
import Accelerate

enum PipelineError: Error{
    case invalidInput(String)
    case creationError(String)
    case genericError(String)
}

class PipelineStep{
    var inputs: [PipelineData]
    var outputs: [PipelineData]
    
    init(){
        self.inputs = []
        self.outputs = []
    }
    
    func removeAllInputs(){
        self.inputs.removeAll()
    }
    
    func addInput(data: PipelineData){
        self.inputs.append(data)
    }
    
    func addInputs(data: [PipelineData]){
        self.inputs = data
    }
    
    func execute() throws{
        
    }
    
    func getInputData<T>(index: Int, type: T.Type) throws -> T{
        guard let inputData = self.inputs[index].associatedValue(type: type) else{
            throw PipelineError.invalidInput("The \(String(describing: self)) has not found the input of type \(T.self) at index \(index).")
        }
        return inputData
    }
    
    func checkNumberOfInputs(expected: Int) throws{
        if self.inputs.count != expected{
            throw PipelineError.invalidInput("The \(String(describing: self)) expects \(expected) input(s), but were given \(self.inputs.count) input(s).")
        }
    }
    
    /*
    deinit {
        for data in self.outputs{
            switch data {
            case .vimageBuffer(let buffer):
                buffer.free()
            default:
                continue
            }
        }
    }
    */
}
/*
extension PipelineStep{
    func addInput(data: [Float]){
        self.inputs.append(.floatBuffer(data))
    }
    
    func addInput(data: vImage_Buffer){
        self.inputs.append(.vimageBuffer(data))
    }
}
*/
