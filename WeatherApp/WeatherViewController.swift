// ViewController.swift
import UIKit
import Combine
import SnapKit

final class WeatherViewController: UIViewController {

    private let viewModel: WeatherViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.loadData()
    }

    init() {
        let service = WeatherService(apiKey: Bundle.main.weatherAPIKey)
        viewModel = WeatherViewModel(service: service)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        tableView.register(CurrentWeatherCell.self, forCellReuseIdentifier: "CurrentCell")
        tableView.register(HourlyForecastCell.self, forCellReuseIdentifier: "HourlyCell")
        tableView.register(DailyForecastCell.self, forCellReuseIdentifier: "DailyCell")
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.refreshControl = refreshControl

        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)

        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(errorLabel)
        view.addSubview(retryButton)

        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        errorLabel.textAlignment = .center
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        retryButton.setTitle("Повторить", for: .normal)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        retryButton.snp.makeConstraints {
            $0.top.equalTo(errorLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
    }

    private func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self else { return }

                if !refreshControl.isRefreshing {
                    activityIndicator.isHidden = !isLoading
                    isLoading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
                }

                if !isLoading {
                    refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)

        viewModel.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (error: Error?) in
                guard let self else { return }
                errorLabel.text = error?.localizedDescription
                errorLabel.isHidden = error == nil
                retryButton.isHidden = error == nil
                tableView.isHidden = error != nil
            }
            .store(in: &cancellables)

        Publishers.CombineLatest4(viewModel.$location, viewModel.$currentWeather, viewModel.$hourlyForecast, viewModel.$dailyForecast)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    @objc private func retryTapped() {
        viewModel.loadData()
    }

    @objc private func refreshPulled() {
        viewModel.loadData()
    }
}

extension WeatherViewController: UITableViewDataSource {
    private enum Sections: Int, CaseIterable {
        case current
        case hourly
        case forecast
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Sections(rawValue: section) else {
            return 0
        }
        switch section {
        case .current:
            return 1
        case .hourly:
            return 1
        case .forecast:
            return viewModel.dailyForecast?.count ?? 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Sections(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        switch section {
        case .current:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CurrentCell", for: indexPath) as? CurrentWeatherCell,
                  let location = viewModel.location,
                  let current = viewModel.currentWeather else {
                return UITableViewCell()
            }
            cell.configure(with: current, name: location.name)
            return cell
        case .hourly:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "HourlyCell", for: indexPath) as? HourlyForecastCell,
                  let hourlyWeather = viewModel.hourlyForecast else {
                return UITableViewCell()
            }
            cell.configure(with: hourlyWeather)
            return cell
        case .forecast:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "DailyCell", for: indexPath) as? DailyForecastCell,
                  let dailyForecast = viewModel.dailyForecast else {
                return UITableViewCell()
            }
            cell.configure(with: dailyForecast[indexPath.row])
            return cell
        }
    }
}

private extension Bundle {
    var weatherAPIKey: String {
        guard let key = object(forInfoDictionaryKey: "WeatherAPIKey") as? String else {
            fatalError("⚠️ WeatherAPIKey not found in Info.plist")
        }
        return key
    }
}
