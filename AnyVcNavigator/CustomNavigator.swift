//
//  CustomNavigator.swift
//  AnyVcNavigator
//
//  Created by Arjun Baru on 28/06/20.
//  Copyright © 2020 Arjun Baru. All rights reserved.
//

import Foundation
import UIKit

struct Step {
    let guider: NextStepGuider
    let validator: NextStepValidator
}

struct SequenceQueue {
    let sequenceList: [Step]

    func checkForNextStep() -> Step? {
        for step in sequenceList {
            if step.validator.shouldMoveForward() {
                return step
            }
        }
        return nil
    }
}

public protocol NextStepValidator {
    func shouldMoveForward() -> Bool
}

enum ValidateStatus: NextStepValidator {
    case pending
    case inProgress
    case completed

    func shouldMoveForward() -> Bool {
        switch self {
        case .pending:
            return true
        case .inProgress, .completed:
            return false
        }
    }

}

protocol NextStepGuider {
    func routeToViewController()
    func getNextStep() -> NextStepGuider?
}

protocol SequenceManager {
    var sequenceOfSteps: SequenceQueue { get set }
    func loadInitialViewController()
    func getNextStepInOnboarding(currentStep: NextStepGuider)
}

extension SequenceManager {
    func loadInitialViewController() {
        sequenceOfSteps.checkForNextStep()?.guider.routeToViewController()
    }
}

func getSequenceOfSteps() -> SequenceQueue {
    let step1 = Step(guider: NextViewController.red, validator: ValidateStatus.pending)
    let step2 = Step(guider: NextViewController.yellow, validator: ValidateStatus.pending)
    let step3 = Step(guider: NextViewController.green, validator: ValidateStatus.pending)
    let step4 = Step(guider: NextViewController.blue, validator: ValidateStatus.pending)
    let step5 = Step(guider: NextViewController.brown, validator: ValidateStatus.pending)
    return SequenceQueue(sequenceList: [step1, step3, step2, step4, step5])
}

final class NavigationManager: SequenceManager {
    var sequenceOfSteps: SequenceQueue

    private init(sequenceOfSteps: SequenceQueue) { self.sequenceOfSteps = sequenceOfSteps }

    // 1
    static let shared = NavigationManager(sequenceOfSteps: getSequenceOfSteps())

    // 2
    func getNextStepInOnboarding(currentStep: NextStepGuider) {
        guard let step = currentStep.getNextStep(), let nextStep = step as? NextViewController else { return }
        for step in sequenceOfSteps.sequenceList {
            if let guider = step.guider as? NextViewController,
                guider == nextStep {
                if step.validator.shouldMoveForward() {
                    nextStep.routeToViewController()
                    break
                } else {
                    getNextStepInOnboarding(currentStep: nextStep)
                    break
                }
            }
        }
    }
}

enum NextViewController: String, NextStepGuider {
    case red
    case yellow
    case green
    case blue
    case brown

// 1
    func routeToViewController() {
        var nextViewController: UIViewController!

        switch self {
        case .red:
            nextViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(identifier: "RedViewController") as! RedViewController
        case .yellow:
            nextViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(identifier: "YellowViewController") as! YellowViewController
        case .green:
            nextViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(identifier: "GreenViewController") as! GreenViewController
        case .blue:
            nextViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(identifier: "BlueViewController") as! BlueViewController
        case .brown:
            nextViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(identifier: "BrownViewController") as! BrownViewController
        }

         pustToTopMostViewController(vc: nextViewController)
    }

    // 2
    func getNextStep() -> NextStepGuider? {
        switch self {
        case .red: return NextViewController.yellow
        case .yellow: return NextViewController.green
        case .green: return NextViewController.blue
        case .blue: return NextViewController.brown
        case .brown: return nil
        }
    }
}

func pustToTopMostViewController(vc: UIViewController) {
    let navVC = UIApplication.shared.windows.first?.topMostViewController()
    navVC?.pushViewController(vc, animated: true)
}

extension UIWindow {
    func topMostViewController() -> UINavigationController? {
        guard let rootViewController = self.rootViewController else {
            return UINavigationController()
        }

        return rootViewController as? UINavigationController
    }
}
