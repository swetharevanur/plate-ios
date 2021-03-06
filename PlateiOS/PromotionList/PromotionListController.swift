//
//  PromotionListController.swift
//  PlateiOS
//
//  Created by Renner Leite Lucena on 10/20/17.
//  Copyright © 2017 Renner Leite Lucena. All rights reserved.
//

import Foundation
import UIKit

final class PromotionListController {
    
    let promotionListService = PromotionListService()
    var promotionList = PromotionListModel()
    
    let username: String
    unowned let promotionListProtocol: PromotionListProtocol
    
    init(username: String, promotionListProtocol: PromotionListProtocol) {
        self.username = username
        self.promotionListProtocol = promotionListProtocol
    }
}

extension PromotionListController {
    
    func initializePromotionList(username: String) {
        promotionListProtocol.showLoading()
        
        promotionListService.readPromotionsToGo(username: username, completionReadPromotionsToGo: { [weak self] success, toGoPromotions in
            self?.handleReadPromotionsToGo(success: success, toGoPromotions: toGoPromotions, username: username)
        })
        
        promotionListProtocol.hideLoading()
    }
    
    func respondToCellButtonClickOnController(promotionModel: PromotionModel, firstClick: Bool) {
        if(firstClick) {
            promotionListService.createRequest(username: username, promotion_id: promotionModel.promotion_id, request_code: "0", completionCreateRequest: { [weak self] success in
                self?.handleCreateRequestGoing(success: success, promotionModel: promotionModel)
            })
        }else {
            let noFoodDialogViewController = UIStoryboard.init(name: "NoFoodDialog", bundle: nil).instantiateViewController(withIdentifier: "NoFoodDialog") as! NoFoodDialogViewController
            
            noFoodDialogViewController.promotionModel = promotionModel
            noFoodDialogViewController.positiveFunction = { [weak self] in
                self?.promotionListService.createRequest(username: (self?.username)!, promotion_id: promotionModel.promotion_id, request_code: "1", completionCreateRequest: { [weak self] success in
                    self?.handleCreateRequestNoFoodLeft(success: success, promotionModel: promotionModel)
            })}
            
            promotionListProtocol.presentViewController(controller: noFoodDialogViewController)
        }
    }
    
    func respondToPlusButtonClick() {
        let addPromotionDialogViewController = UIStoryboard.init(name: "AddPromotionDialog", bundle: nil).instantiateViewController(withIdentifier: "AddPromotionDialog") as! AddPromotionDialogViewController
        
        addPromotionDialogViewController.positiveFunction = { [weak self] promotionModel in
            self?.promotionListService.createPromotion(title: promotionModel.title, start_time: promotionModel.start_time, end_time: promotionModel.end_time, location: promotionModel.location, completionCreatePromotion: { [weak self] success, promotionModel in
                self?.handleCreatePromotion(success: success, promotionModel: promotionModel)
            })}
        
        addPromotionDialogViewController.errorFunction = { [weak self] in
            self?.delayWithSeconds(0.25) {
                self?.promotionListProtocol.showErrorMessage(title: "Error", message: "Something went wrong. Please, check your internet connection, inputs and try again.")
            }
        }
        
        promotionListProtocol.presentViewController(controller: addPromotionDialogViewController)
    }
    
    fileprivate func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
}

extension PromotionListController {
    
    func handleReadPromotionsToGo(success: Bool, toGoPromotions: [PromotionModel]?, username: String) {
        if(success) {
            for model in toGoPromotions ?? [] {
                promotionList.promotions.append(model)
                promotionList.promotionsStatus[model] = true
            }
            
            promotionListService.readPromotionsGoing(username: username, completionReadPromotionsGoing: { [weak self] success, goingPromotions in
                self?.handleReadPromotionsGoing(success: success, goingPromotions: goingPromotions)
            })
        }else {
            promotionListProtocol.showErrorMessage(title: "Error", message: "Something went wrong. Please, try again.")
        }
    }
    
    func handleReadPromotionsGoing(success: Bool, goingPromotions: [PromotionModel]?) {
        if(success) {
            for model in goingPromotions ?? [] { // change this later maybe
                promotionList.promotions.append(model)
                promotionList.promotionsStatus[model] = false
            }
            
            promotionListProtocol.loadTable()
        }else {
            promotionListProtocol.showErrorMessage(title: "Error", message: "Something went wrong. Please, try again.")
        }
    }
    
    func handleCreateRequestGoing(success: Bool, promotionModel: PromotionModel) {
        if(success) {
            promotionList.promotionsStatus[promotionModel] = false
            promotionListProtocol.reloadTable()
        }else {
              promotionListProtocol.showErrorMessage(title: "Error", message: "Sorry. This action in unavailable (event has no more food or is over).")
        }
    }
    
    func handleCreateRequestNoFoodLeft(success: Bool, promotionModel: PromotionModel) {
        if(success) {
            promotionList.removePromotion(promotionModel: promotionModel)
            promotionListProtocol.reloadTable()
        }else {
            promotionListProtocol.showErrorMessage(title: "Error", message: "Sorry. This action in unavailable (event has no more food or is over).")
        }
    }
    
    func handleCreatePromotion(success: Bool, promotionModel: PromotionModel?) {
        if(success && promotionModel != nil) {
            promotionList.addPromotion(promotionModel: promotionModel!)
            promotionListProtocol.reloadTable()
        }else {
            promotionListProtocol.showErrorMessage(title: "Error", message: "Something went wrong. Please, check your internet connection, inputs and try again.")
        }
    }
}
