import UIKit
import SnapKit

final class CurrentWeatherCell: UITableViewCell {
    private let todayLabel: UILabel = {
        let today = Date()
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .systemGray
        label.text = "Сегодня \(dateFormatter.string(from: Date()))"
        return label
    }()

    private let cityLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 20)
        return label
    }()

    private let tempLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        return label
    }()

    private let conditionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [todayLabel, cityLabel, tempLabel, conditionLabel])
        stack.axis = .vertical
        stack.spacing = 4

        contentView.addSubview(stack)
        contentView.addSubview(iconView)

        stack.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview().inset(16)
        }

        iconView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(16)
            $0.width.height.equalTo(50)
        }
    }

    func configure(with weather: CurrentWeather, name: String) {
        cityLabel.text = name
        tempLabel.text = String("\(weather.tempC)\u{2103}")
        conditionLabel.text = weather.condition.text
        if let icon = URL(string: "https:\(weather.condition.icon)") {
            iconView.load(url: icon)
        } else {
            iconView.image = nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
    }
}

final class HourlyForecastCell: UITableViewCell {

    private var scrollView = UIScrollView()
    private var stackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        scrollView.showsHorizontalScrollIndicator = false
        stackView.axis = .horizontal
        stackView.spacing = 16

        contentView.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(8)
            $0.height.equalTo(100).priority(.high)
        }

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }
    }

    func configure(with items: [HourlyWeather]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for item in items {
            let view = HourView()
            view.configure(time: item.time, temp: item.tempC, iconString: item.condition.icon)
            stackView.addArrangedSubview(view)
        }
    }
}

final class DailyForecastCell: UITableViewCell {

    private let dateLabel = UILabel()
    private let tempLabel = UILabel()
    private let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(dateLabel)
        contentView.addSubview(tempLabel)
        contentView.addSubview(iconView)

        dateLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(iconView.snp.trailing).offset(16)
        }

        tempLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(16)
        }

        iconView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().inset(16)
            $0.width.height.equalTo(40)
            $0.verticalEdges.equalToSuperview().inset(8).priority(.high)
        }

        iconView.contentMode = .scaleAspectFit
        dateLabel.font = .systemFont(ofSize: 16)
        tempLabel.font = .systemFont(ofSize: 16)
    }

    func configure(with forecast: ForecastDay) {
        let date = Date(timeIntervalSince1970: forecast.dateEpoch)
        dateLabel.text = dateFormatter.string(from: date)
        tempLabel.text = "\(Int(forecast.day.mintempC))\u{2103} / \(Int(forecast.day.maxtempC))\u{2103}"
        if let url = URL(string: "https:\(forecast.day.condition.icon)") {
            iconView.load(url: url)
        } else {
            iconView.image = nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
    }
}

final class HourView: UIView {

    private let timeLabel = UILabel()
    private let iconView = UIImageView()
    private let tempLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [timeLabel, iconView, tempLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4

        timeLabel.snp.makeConstraints {
            $0.height.equalTo(20)
        }
        tempLabel.snp.makeConstraints {
            $0.height.equalTo(20)
        }

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().priority(.high)
        }

        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints {
            $0.width.height.equalTo(30)
        }

        timeLabel.font = .systemFont(ofSize: 14)
        tempLabel.font = .systemFont(ofSize: 14)
    }

    func configure(time: String, temp: Double, iconString: String) {
        let hour = time.components(separatedBy: " ").last ?? time
        timeLabel.text = hour
        tempLabel.text = "\(Int(temp))\u{2103}"
        if let iconURL = URL(string: "https:\(iconString)") {
            iconView.load(url: iconURL)
        }
    }
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async { [weak self] in
                    self?.image = image
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.image = UIImage(systemName: "questionmark")
                }
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ru_RU")
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()
